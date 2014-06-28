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
module HolePunch
  class Service
    attr_accessor :id, :groups

    def initialize(id)
      @id = id
      @groups = []
    end
  end

  class SecurityGroup
    attr_accessor :id, :desc, :dependency, :ingresses

    def initialize(id, opts = {})
      opts = {
        dependency: false
      }.merge(opts)

      @id         = id
      @desc       = id
      @dependency = opts[:dependency]
      @ingresses  = []
    end

    def include_ingress?(type, ports, source)
      ports = ports.first if ports.is_a?(Range) and ports.size == 1

      ingresses.any? do |ingress|
        ingress.type == type && ingress.ports == ports && ingress.sources.include?(source)
      end
    end
  end

  class Permission < Struct.new(:type, :ports, :sources)
    def icmp?
      type == :icmp
    end

    def tcp?
      type == :tcp
    end

    def udp?
      type == :udp
    end
  end

  class Definition
    attr_reader :env
    attr_reader :groups
    attr_reader :services

    class << self
      def build(file, env)
        filename = Pathname.new(file).expand_path
        unless filename.file?
          raise SecurityGroupsFileNotFoundError, "#{filename} not found"
        end

        DSL.evaluate(file, env)
      end
    end

    def initialize(env = nil)
      @env = env
      @groups = {}
      @services = {}
    end

    def add_group(group)
      raise DuplicateGroupError, "another group already exists with id #{id}" if groups.include?(group.id)
      groups[group.id] = group
    end

    def validate!
      # verify group references are defined
      groups.each do |id, group|
        group.ingresses.each do |ingress|
          ingress.sources.each do |source|
            next if HolePunch.cidr?(source)
            unless groups.include?(source)
              raise GroupError, "group '#{source}' referenced by group '#{id}' does not exist"
            end
          end
        end
      end
    end
  end
end
