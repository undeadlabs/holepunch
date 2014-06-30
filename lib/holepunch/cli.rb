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
require 'holepunch'
require 'thor'

module HolePunch
  class CLI < Thor
    def initialize(*args)
      super
      Logger.output = LoggerOutputStdio.new
    end

    default_task :apply

    option :'aws-access-key',         aliases: :A, type: :string, default: ENV['AWS_ACCESS_KEY_ID'], desc:
      'Your AWS Access Key ID'
    option :'aws-secret-access-key',  aliases: :k, type: :string, default: ENV['AWS_SECRET_ACCESS_KEY'], desc:
      'Your AWS API Secret Access Key'
    option :'aws-region',             aliases: :r, type: :string, default: ENV['AWS_REGION'], desc:
      'Your AWS region'
    option :env,                      aliases: :e, type: :string, desc:
      'Set the environment'
    option :file,                     aliases: :f, type: :string, default: "#{Dir.pwd}/SecurityGroups", desc:
      'The location of the SecurityGroups file to use'
    option :verbose,                  aliases: :v, type: :boolean, desc:
      'Enable verbose output'
    desc 'apply [OPTIONS]', 'apply the defined security groups to ec2'
    def apply
      Logger.fatal("AWS Access Key ID not defined. Use --aws-access-key or AWS_ACCESS_KEY_ID") if options[:'aws-access-key'].nil?
      Logger.fatal("AWS Secret Access Key not defined. Use --aws-secret-access-key or AWS_SECRET_ACCESS_KEY") if options[:'aws-secret-access-key'].nil?
      Logger.fatal("AWS Region not defined. Use --aws-region or AWS_REGION") if options[:'aws-region'].nil?
      Logger.verbose = options[:verbose]

      definition = Definition.build(options[:file], options[:env])
      ec2 = EC2.new({
        access_key_id:     options[:'aws-access-key'],
        secret_access_key: options[:'aws-secret-access-key'],
        region:            options[:'aws-region'],
      })
      ec2.apply(definition)

    rescue EnvNotDefinedError => e
      Logger.fatal('You have security groups that use an environment, but you did not specify one. See --help')
    rescue HolePunchError => e
      Logger.fatal(e.message)
    end

    option :env,                      aliases: :e, type: :string, desc:
      'Set the environment'
    option :file,                     aliases: :f, type: :string, default: "#{Dir.pwd}/SecurityGroups", desc:
      'The location of the SecurityGroups file to use'
    option :list,                                  type: :boolean, desc:
      'List all services instead'
    option :verbose,                  aliases: :v, type: :boolean, desc:
      'Enable verbose output'
    desc 'service NAME', 'output the list of security groups for a service'
    def service(name = nil)
      Logger.verbose = options[:verbose]

      definition = Definition.build(options[:file], options[:env])

      if options[:list]
        definition.services.keys.sort.each do |name|
          puts name
        end
      else
        service = definition.services[name]
        Logger.fatal("service '#{name}' not found") if service.nil?
        puts service.groups.sort.join(',')
      end

    rescue EnvNotDefinedError => e
      Logger.fatal('You have security groups that use an environment, but you did not specify one. See --help')
    rescue HolePunchError => e
      Logger.fatal(e.message)
    end

    desc 'version', 'display the version and exit'
    def version
      puts VERSION
    end
    map %w(-v --version) => :version

    protected
      def exit_on_failure?
        true
      end
  end
end
