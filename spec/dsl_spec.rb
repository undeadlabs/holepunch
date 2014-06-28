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
require 'spec_helper'

include HolePunch

describe ::HolePunch::DSL do
  describe '#evaluate' do
    it 'parses an empty group definition' do
      dsl = dsl_eval <<-EOS
        group 'holepunch'
      EOS

      expect(dsl.groups.count).to eq(1)
      expect(dsl.groups).to include('holepunch')
    end

    it 'parses an empty group definition with a symbol name' do
      dsl = dsl_eval <<-EOS
        group :holepunch
      EOS

      expect(dsl.groups.count).to eq(1)
      expect(dsl.groups).to include('holepunch')
    end

    it 'should default the description to the group name' do
      dsl = dsl_eval <<-EOS
        group 'holepunch'
      EOS

      expect(dsl.groups['holepunch'].desc).to eq('holepunch')
    end

    it 'parses a group description' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          desc 'some description'
        end
      EOS

      expect(dsl.groups['holepunch'].desc).to eq('some description')
    end

    it 'should create an empty group with no permissions' do
      dsl = dsl_eval <<-EOS
        group 'holepunch'
      EOS
      expect(dsl.groups['holepunch'].ingresses).to be_empty
    end

    it 'defaults a tcp permission with no sources to 0.0.0.0/0' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:tcp)
      expect(group.ingresses.first.ports).to eq(80)
      expect(group.ingresses.first.sources).to eq(['0.0.0.0/0'])
    end

    it 'defaults a udp permission with no sources to 0.0.0.0/0' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:udp)
      expect(group.ingresses.first.ports).to eq(80)
      expect(group.ingresses.first.sources).to eq(['0.0.0.0/0'])
    end

    it 'defaults an icmp permission with no sources to 0.0.0.0/0' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          icmp
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:icmp)
      expect(group.ingresses.first.ports).to be_nil
      expect(group.ingresses.first.sources).to eq(['0.0.0.0/0'])
    end

    it 'allows ping to be used as an alias for icmp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          ping
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:icmp)
      expect(group.ingresses.first.ports).to be_nil
      expect(group.ingresses.first.sources).to eq(['0.0.0.0/0'])
    end

    it 'accepts multiple sources for tcp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80, '1.2.3.4/32', '10.0.0.0/16'
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:tcp)
      expect(group.ingresses.first.ports).to eq(80)
      expect(group.ingresses.first.sources).to eq(['1.2.3.4/32', '10.0.0.0/16'])
    end

    it 'accepts multiple sources for udp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80, '1.2.3.4/32', '10.0.0.0/16'
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:udp)
      expect(group.ingresses.first.ports).to eq(80)
      expect(group.ingresses.first.sources).to eq(['1.2.3.4/32', '10.0.0.0/16'])
    end

    it 'accepts multiple sources for icmp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          ping '1.2.3.4/32', '10.0.0.0/16'
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:icmp)
      expect(group.ingresses.first.ports).to be_nil
      expect(group.ingresses.first.sources).to eq(['1.2.3.4/32', '10.0.0.0/16'])
    end

    it 'accepts multiple sources as an array for tcp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80, ['1.2.3.4/32', '10.0.0.0/16']
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:tcp)
      expect(group.ingresses.first.ports).to eq(80)
      expect(group.ingresses.first.sources).to eq(['1.2.3.4/32', '10.0.0.0/16'])
    end

    it 'accepts multiple sources as an array for udp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80, ['1.2.3.4/32', '10.0.0.0/16']
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:udp)
      expect(group.ingresses.first.ports).to eq(80)
      expect(group.ingresses.first.sources).to eq(['1.2.3.4/32', '10.0.0.0/16'])
    end

    it 'accepts multiple sources as an array for icmp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          ping ['1.2.3.4/32', '10.0.0.0/16']
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:icmp)
      expect(group.ingresses.first.ports).to be_nil
      expect(group.ingresses.first.sources).to eq(['1.2.3.4/32', '10.0.0.0/16'])
    end

    it 'accepts a port range for tcp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80..90
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:tcp)
      expect(group.ingresses.first.ports).to eq(80..90)
      expect(group.ingresses.first.sources).to eq(['0.0.0.0/0'])
    end

    it 'accepts a port range for udp' do
      dsl = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80..90
        end
      EOS

      group = dsl.groups['holepunch']
      expect(group.ingresses.count).to eq(1)
      expect(group.ingresses.first.type).to eq(:udp)
      expect(group.ingresses.first.ports).to eq(80..90)
      expect(group.ingresses.first.sources).to eq(['0.0.0.0/0'])
    end

    it 'fails if a group references an undefined group' do
      expect {
        definition = dsl_eval <<-EOS
          group 'holepunch' do
            tcp 80, 'does-not-exist'
          end
        EOS
      }.to raise_error(GroupError)
    end

    it 'parses an empty service definition' do
      dsl = dsl_eval <<-EOS
        service 'app'
      EOS

      expect(dsl.services.keys).to match_array(['app'])
    end

    it 'parses an empty service definition with a symbol name' do
      dsl = dsl_eval <<-EOS
        service :app
      EOS

      expect(dsl.services.keys).to match_array(['app'])
    end

    it 'parses a single group for a service' do
      dsl = dsl_eval <<-EOS
        service :app do
          groups 'admin'
        end
      EOS

      expect(dsl.services['app'].groups).to match_array(['admin'])
    end

    it 'parses a list of groups for a service' do
      dsl = dsl_eval <<-EOS
        service :app do
          groups 'admin', ['http', 'db']
        end
      EOS

      expect(dsl.services['app'].groups).to match_array(%w(admin http db))
    end

    it 'supports env in the service name' do
      dsl = dsl_eval 'dev', <<-'EOS'
        service "#{env}-app"
      EOS
      expect(dsl.services.keys).to match_array(%w(dev-app))
    end

    it 'supports env for service groups' do
      dsl = dsl_eval 'dev', <<-'EOS'
        service :app do
          groups ["#{env}-admin"]
        end
      EOS
      expect(dsl.services['app'].groups).to match_array(%w(dev-admin))
    end
  end
end
