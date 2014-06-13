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
  class DSL
    attr_reader :groups

    def self.evaluate(filename, env = nil)
      DSL.new(env).eval_dsl(filename)
    end

    def initialize(env)
      @definition = Definition.new(env)
      @group = nil
      @groups = {}
    end

    def eval_dsl(filename)
      instance_eval(HolePunch.read_file(filename.to_s), filename.to_s, 1)
      @definition.validate!
      @definition
    rescue SyntaxError => e
      raise SecurityGroupsFileError, "SecurityGroups syntax error #{e.message.gsub("#{filename.to_s}:", 'on line ')}"
    end

    def env
      raise EnvNotDefinedError, 'env not defined' if @definition.env.nil?
      @definition.env
    end

    def depends(id)
      id = id.to_s
      raise GroupError, "duplicate group id #{id}" if @definition.groups.include?(id)
      raise HolePunchSyntaxError, "dependency group #{id} cannot have a block" if block_given?
      @group            = SecurityGroup.new(id, dependency: true)
      @definition.add_group(@group)
      yield if block_given?
    ensure
      @group = nil
    end

    def group(id, &block)
      id = id.to_s
      raise GroupError, "duplicate group id #{id}" if @definition.groups.include?(id)
      @group            = SecurityGroup.new(id, dependency: false)
      @definition.add_group(@group)
      yield if block_given?
    ensure
      @group = nil
    end

    def desc(str)
      raise HolePunchSyntaxError, 'desc must be used inside a group' if @group.nil?
      raise HolePunchSyntaxError, 'desc cannot be used in a dependency group (the group is expected to be already defined elsewhere)' if @group.dependency
      @group.desc = str
    end

    def icmp(*sources)
      raise HolePunchSyntaxError, 'ping/icmp must be used inside a group' if @group.nil?
      raise HolePunchSyntaxError, 'ping/icmp cannot be used in a dependency group (the group is expected to be already defined elsewhere)' if @group.dependency
      sources << '0.0.0.0/0' if sources.empty?
      @group.ingresses << Permission.new(:icmp, nil, sources.flatten)
    end
    alias_method :ping, :icmp

    def tcp(ports, *sources)
      raise HolePunchSyntaxError, 'tcp must be used inside a group' if @group.nil?
      raise HolePunchSyntaxError, 'tcp cannot be used in a dependency group (the group is expected to be already defined elsewhere)' if @group.dependency
      sources << '0.0.0.0/0' if sources.empty?
      @group.ingresses << Permission.new(:tcp, ports, sources.flatten)
    end

    def udp(ports, *sources)
      raise HolePunchSyntaxError, 'udp must be used inside a group' if @group.nil?
      raise HolePunchSyntaxError, 'udp cannot be used in a dependency group (the group is expected to be already defined elsewhere)' if @group.dependency
      sources << '0.0.0.0/0' if sources.empty?
      @group.ingresses << Permission.new(:udp, ports, sources.flatten)
    end
  end
end
