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
require 'aws-sdk'
require 'holepunch/definition'
require 'holepunch/dsl'
require 'holepunch/ec2'
require 'holepunch/logger'
require 'holepunch/version'

module HolePunch
  class HolePunchError < StandardError; end

  class EnvNotDefinedError < HolePunchError; end
  class GroupError < HolePunchError; end
  class GroupDoesNotExistError < HolePunchError; end
  class SecurityGroupsFileNotFoundError < HolePunchError; end
  class SecurityGroupsFileError < HolePunchError; end
  class ServiceDoesNotExistError < HolePunchError; end

  class << self
    # Applies the given SecurityGroups file to EC2.
    #
    # @param filename [String]      the path to the SecurityGroups file
    # @param env      [String, nil] the environment
    # @param opts     [Hash]        additional options
    #
    # @option opts [String] :aws_access_key_id      the AWS access key id
    # @option opts [String] :aws_secret_access_key  the AWS secret access key
    # @option opts [String] :aws_region             the AWS region
    def apply(filename, env, opts = {})
      definition = Definition.build(filename, env)
      ec2 = EC2.new(opts)
      ec2.apply(definition)
    end

    # Tests if a list of security groups are all defined in the SecurityGroups
    # file.
    #
    # @param filename [String]        the path to the SecurityGroups file
    # @param env      [String, nil]   the environment
    # @param groups   [Array<String>] the list of security groups to check
    def defined?(filename, env, groups)
      definition = Definition.build(filename, env)
      groups.all? do |group_id|
        definition.groups.include?(group_id)
      end
    end

    # Examines the given SecurityGroups file for the given service and returns
    # a list of the security groups that make up that service.
    #
    # @param filename [String]      the path to the SecurityGroups file
    # @param env      [String, nil] the environment
    # @param name     [String]      the name of the service to query
    #
    # @return [Array<String>] the list of security group names
    def service_groups(filename, env, name)
      definition = Definition.build(filename, env)
      service = definition.services[name]
      raise ServiceDoesNotExistError, "service '#{name}' not found" if service.nil?
      service.groups
    end

    #
    # private helpers
    #

    # @private
    def cidr?(value)
      value.to_s =~ /\d+\.\d+\.\d+\.\d+\/\d+/
    end

    # @private
    def read_file(file)
      content = File.open(file, 'rb') do |io|
        io.read
      end
    end
  end
end
