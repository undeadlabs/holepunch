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

module Spec
  module Helpers
    def delete_groups(ec2, *names)
      names.flatten.each do |name|
        delete_group(ec2, name)
      end
    end

    def delete_group(ec2, name)
      group = ec2_group(ec2, name)
      if group
        group.delete
      end
    end

    def dsl_eval(content_or_env, content = nil)
      if content.nil?
        content = content_or_env
        env = nil
      else
        env = content_or_env
      end
      set_security_groups_content('SecurityGroups', content)
      DSL.evaluate('SecurityGroups', env)
    end

    def set_security_groups_content(filename, content)
      allow_any_instance_of(Pathname).to receive(:file?).and_return(true)
      allow(HolePunch).to receive(:read_file).and_return(content)
    end

    def ec2_group(ec2, name)
      name = name.to_s
      ec2.security_groups.detect { |group| group.name == name }
    end

    def ec2_group_ingress(ec2_group, protocol, ports)
      ports = ports..ports unless ports.is_a?(Range)
      ec2_group.ingress_ip_permissions.detect do |perm|
        perm.protocol == protocol && perm.port_range == ports
      end
    end
  end
end

RSpec.configure do |config|
  config.include Spec::Helpers

  config.filter_run_excluding integration: true
end
