#
# Copyright (C) 2014 Undead Labs, LLC
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'shellwords'

module HolePunch
  class EC2
    attr_reader :ec2
    attr_reader :region

    def initialize(opts = {})
      opts = {
        access_key_id:     ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
        region:            ENV['AWS_REGION'],
      }.merge(opts)

      AWS.config(opts)

      @ec2    = AWS::EC2.new
      @region = @ec2.regions[opts[:region]]
    end

    def apply(definition)
      if definition.env.nil?
        Logger.log("Creating security groups in '#{@region.name}' region")
      else
        Logger.log("Creating security groups for '#{definition.env}' environment in '#{@region.name}' region")
      end

      # get the security group data from the AWS servers
      fetch!

      # ensure dependency groups exist
      definition.groups.select { |id, group| group.dependency }.each do |id, group|
        unless exists?(id)
          raise GroupDoesNotExistError, "Dependent security group '#{id}' does not exist"
        end
      end

      # find/create the groups
      ec2_groups = {}
      definition.groups.each do |id, group|
        ec2_group = find(id)
        if ec2_group.nil?
          Logger.log(:create, id)
          ec2_group = create(id, group.desc)
        end
        ec2_groups[id] = ec2_group
      end

      definition.groups.each do |id, group|
        next if group.dependency
        ec2_group = ec2_groups[id]

        # revoke existing ingresses no longer desired
        ec2_group.ingress_ip_permissions.each do |ec2_perm|
          revoke_sources = []
          ec2_perm.groups.each do |source|
            unless group.include_ingress?(ec2_perm.protocol, ec2_perm.port_range, source.name)
              revoke_sources << source
            end
          end
          ec2_perm.ip_ranges.each do |source|
            unless group.include_ingress?(ec2_perm.protocol, ec2_perm.port_range, source)
              revoke_sources << source
            end
          end
          unless revoke_sources.empty?
            Logger.log("revoke #{ec2_perm.protocol}", "#{id} #{sources_list_to_s(revoke_sources)}")
            ec2_group.revoke_ingress(ec2_perm.protocol, ec2_perm.port_range, *revoke_sources)
          end
        end

        # add new ingresses
        group.ingresses.each do |perm|
          new_sources = []
          perm.sources.each do |source|
            if HolePunch.cidr?(source)
              unless group_has_ingress(ec2_group, perm.type, perm.ports, source)
                new_sources << source
              end
            else
              ec2_source_group = ec2_groups[source]
              if ec2_source_group.nil?
                raise GroupDoesNotExistError, "unknown security group '#{source}"
              end
              unless group_has_ingress(ec2_group, perm.type, perm.ports, ec2_source_group)
                new_sources << ec2_source_group
              end
            end
          end
          unless new_sources.empty?
            Logger.log(perm.type, "#{id} #{sources_list_to_s(new_sources)}")
            ec2_group.authorize_ingress(perm.type, perm.ports, *new_sources)
          end
        end
      end
    end


    private
      def fetch!
        @groups = @region.security_groups.to_a
      end

      def create(name, description)
        group = @region.security_groups.create(name, description: description)
        @groups << group
        group
      end

      def find(name)
        @groups.detect { |group| group.name == name }
      end

      def exists?(name)
        !find(name).nil?
      end

      def group_has_ingress(group, protocol, ports, source)
        ports = ports..ports unless ports.is_a?(Range)
        is_cidr = HolePunch.cidr?(source)
        group.ingress_ip_permissions.any? do |perm|
          if is_cidr
            perm.protocol == protocol && perm.port_range == ports && perm.ip_ranges.include?(source)
          else
            perm.protocol == protocol && perm.port_range == ports && perm.groups.include?(source)
          end
        end
      end

      def sources_list_to_s(sources)
        sources.map do |source|
          if source.is_a?(AWS::EC2::SecurityGroup)
            source.name
          else
            source.to_s
          end.shellescape
        end.sort.join(' ')
      end
  end
end
