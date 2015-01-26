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
require 'pathname'

module HolePunch
  class BaseDSL
    def initialize(env, model)
      @env = env
      @model = model
    end

    def eval_dsl(filename = nil, &block)
      if !filename.nil?
        instance_eval(HolePunch.read_file(filename.to_s), filename.to_s, 1)
      else
        instance_eval(&block) if block_given?
      end
      @model
    end

    def env
      raise EnvNotDefinedError, 'env not defined' if @env.nil?
      @env
    end
  end

  class ServiceDSL < BaseDSL
    def self.evaluate(env, *args, &block)
      new(env, *args).eval_dsl(&block)
    end

    def initialize(env, id)
      super(env, Service.new(id))
    end

    def groups(*ids)
      @model.groups.concat(ids.flatten)
    end
  end

  class GroupDSL < BaseDSL
    def self.evaluate(env, *args, &block)
      new(env, *args).eval_dsl(&block)
    end

    def initialize(env, id, vpc_id)
      @vpc_id = vpc_id
      super(env, SecurityGroup.new(id, dependency: false))
    end

    def desc(str)
      @model.desc = str
    end

    def icmp(*sources)
      @model.ingresses << Permission.new(:icmp, nil, valid_sources(sources))
    end
    alias_method :ping, :icmp

    def tcp(ports, *sources)
      @model.ingresses << Permission.new(:tcp, ports, valid_sources(sources))
    end

    def udp(ports, *sources)
      @model.ingresses << Permission.new(:udp, ports, valid_sources(sources))
    end

    private

    def valid_sources (sources)
      sources = sources.flatten.select do |source|
        if HolePunch.cidr?(source)
          true
        elsif ! @vpc_id
          true
        elsif /vpc/.match(source)
          true
        else
          false
        end
      end
      sources << '0.0.0.0/0' if sources.empty?
      sources
    end
  end

  class DSL < BaseDSL
    def self.evaluate(filename, env, vpc_id = nil)
      path = Pathname.new(filename).expand_path
      unless path.file?
        raise SecurityGroupsFileNotFoundError, "#{filename} not found"
      end

      DSL.new(env, vpc_id).eval_dsl(filename)
    end

    def initialize(env, vpc_id)
      @vpc_id = vpc_id
      super(env, Definition.new(env))
    end

    def eval_dsl(filename)
      super(filename)
      @model.validate!
      @model
    rescue SyntaxError => e
      raise SecurityGroupsFileError, "SecurityGroups syntax error #{e.message.gsub("#{filename.to_s}:", 'on line ')}"
    end

    def depends(id)
      id = id.to_s
      raise GroupError, "duplicate group id #{id}" if @model.groups.include?(id)
      raise HolePunchSyntaxError, "dependency group #{id} cannot have a block" if block_given?
      return if @vpc_id && ! /vpc/.match(id)
      @model.add_group(SecurityGroup.new(id, dependency: true))
    end

    def group(id, &block)
      id = id.to_s
      raise GroupError, "duplicate group id #{id}" if @model.groups.include?(id)
      group = GroupDSL.evaluate(@env, id, @vpc_id, &block)
      return if @vpc_id && ! /vpc/.match(id)
      @model.add_group(group)
    end

    def service(id, &block)
      id = id.to_s
      @model.services[id] = ServiceDSL.evaluate(@env, id, &block)
    end
  end
end
