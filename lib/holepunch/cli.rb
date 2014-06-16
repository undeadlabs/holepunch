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
require 'optparse'

module HolePunch
  class Options < Struct.new(
    :aws_access_key_id,
    :aws_region,
    :aws_secret_access_key,
    :env,
    :filename,
    :verbose
  ); end

  class Cli
    def initialize
      Logger.output = LoggerOutputStdio.new
    end

    def execute!(args)
      opts = parse_opts(args)
      Logger.verbose = opts.verbose

      definition = Definition.build(opts.filename, opts.env)

      ec2 = EC2.new({
        access_key_id:     opts.aws_access_key_id,
        secret_access_key: opts.aws_secret_access_key,
        region:            opts.aws_region,
      })
      ec2.apply(definition)

    rescue EnvNotDefinedError => e
      Logger.fatal('You have security groups that use an environment, but you did not specify one. See --help')
    rescue HolePunchError => e
      Logger.fatal(e.message)
    end

    private
      def parse_opts(args)
        opts                       = Options.new
        opts.aws_access_key_id     = ENV['AWS_ACCESS_KEY_ID']
        opts.aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
        opts.aws_region            = ENV['AWS_REGION']
        opts.env                   = nil
        opts.filename              = "#{Dir.pwd}/SecurityGroups"
        opts.verbose               = false

        OptionParser.new(<<-EOS.gsub(/^ {10}/, '')
          Usage: holepunch [options]

          Options:
        EOS
        ) do |parser|
          parser.on('-A', '--aws-access-key KEY', String, 'Your AWS Access Key ID') do |value|
            opts.aws_access_key_id = value
          end
          parser.on('-e', '--env ENV', String, 'Set the environment') do |value|
            opts.env = value
          end
          parser.on('-f', '--file FILENAME', String, 'The location of the SecurityGroups file to use') do |value|
            opts.filename = value
          end
          parser.on('-K', '--aws-secret-access-key SECRET', String, 'Your AWS API Secret Access Key') do |value|
            opts.aws_secret_access_key = value
          end
          parser.on('-r', '--aws-region REGION', String, 'Your AWS region') do |v|
            opts.aws_region = v
          end
          parser.on('-v', '--verbose', 'verbose output') do |v|
            opts.verbose = v
          end
          parser.on('-V', '--version', 'display the version and exit') do
            puts VERSION
            exit
          end
          parser.on_tail('-h', '--help', 'show this message') do
            puts parser
            exit
          end
        end.parse!(args)

        Logger.fatal("AWS Access Key ID not defined. Use --aws-access-key or AWS_ACCESS_KEY_ID") if opts.aws_access_key_id.nil?
        Logger.fatal("AWS Secret Access Key not defined. Use --aws-secret-access-key or AWS_SECRET_ACCESS_KEY") if opts.aws_secret_access_key.nil?
        Logger.fatal("AWS Region not defined. Use --aws-region or AWS_REGION") if opts.aws_region.nil?

        opts
      end
  end
end
