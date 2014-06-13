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

describe HolePunch::EC2 do
  let(:ec2)    { EC2.new }
  let(:region) { ec2.region }

  after(:each) do
    delete_groups(region, 'holepunch2', 'holepunch')
  end

  describe '.apply' do
    it 'can create an empty group' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      expect(group).to_not be_nil
      expect(group.name).to eq('holepunch')
      expect(group.description).to eq('holepunch')
      expect(group.egress_ip_permissions.to_a).to be_empty
      expect(group.ingress_ip_permissions.to_a).to be_empty
    end

    it 'properly sets the description' do
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          desc 'some description'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      expect(group.description).to eq('some description')
    end

    it 'adds tcp cidr ingresses' do
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80, '127.0.0.1/32'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :tcp, 80)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:tcp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32'])
    end

    it 'adds tcp named ingresses' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
        group 'holepunch2' do
          tcp 80, 'holepunch'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      group2 = ec2_group(region, 'holepunch2')
      perm = ec2_group_ingress(group2, :tcp, 80)
      expect(group2.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:tcp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to eq([group])
      expect(perm.ip_ranges).to be_empty
    end

    it 'adds tcp ingresses with multiple sources' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
        group 'holepunch2' do
          tcp 80, '127.0.0.1/32', 'holepunch'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      group2 = ec2_group(region, 'holepunch2')
      perm = ec2_group_ingress(group2, :tcp, 80)
      expect(group2.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:tcp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to eq([group])
      expect(perm.ip_ranges).to eq(['127.0.0.1/32'])
    end

    it 'adds udp cidr ingresses' do
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80, '127.0.0.1/32'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :udp, 80)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:udp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32'])
    end

    it 'adds udp named ingresses' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
        group 'holepunch2' do
          udp 80, 'holepunch'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      group2 = ec2_group(region, 'holepunch2')
      perm = ec2_group_ingress(group2, :udp, 80)
      expect(group2.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:udp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to eq([group])
      expect(perm.ip_ranges).to be_empty
    end

    it 'adds udp ingresses with multiple sources' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
        group 'holepunch2' do
          udp 80, '127.0.0.1/32', 'holepunch'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      group2 = ec2_group(region, 'holepunch2')
      perm = ec2_group_ingress(group2, :udp, 80)
      expect(group2.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:udp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to eq([group])
      expect(perm.ip_ranges).to eq(['127.0.0.1/32'])
    end

    it 'adds icmp cidr ingresses' do
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          icmp '127.0.0.1/32'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :icmp, 0)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:icmp)
      expect(perm.port_range).to eq(0..0)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32'])
    end

    it 'adds icmp named ingresses' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
        group 'holepunch2' do
          icmp 'holepunch'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      group2 = ec2_group(region, 'holepunch2')
      perm = ec2_group_ingress(group2, :icmp, 0)
      expect(group2.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:icmp)
      expect(perm.port_range).to eq(0..0)
      expect(perm.groups).to eq([group])
      expect(perm.ip_ranges).to be_empty
    end

    it 'adds icmp ingresses with multiple sources' do
      definition = dsl_eval <<-EOS
        group 'holepunch'
        group 'holepunch2' do
          icmp '127.0.0.1/32', 'holepunch'
        end
      EOS
      ec2.apply(definition)

      group = ec2_group(region, 'holepunch')
      group2 = ec2_group(region, 'holepunch2')
      perm = ec2_group_ingress(group2, :icmp, 0)
      expect(group2.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:icmp)
      expect(perm.port_range).to eq(0..0)
      expect(perm.groups).to eq([group])
      expect(perm.ip_ranges).to eq(['127.0.0.1/32'])
    end

    it 'revokes old tcp ingresses' do
      # setup the initial group definition
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80, '127.0.0.1/32', '127.0.0.2/32'
        end
      EOS
      ec2.apply(definition)
      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :tcp, 80)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:tcp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32', '127.0.0.2/32'])

      # change it
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          tcp 80, '127.0.0.1/32', '127.0.0.3/32'
        end
      EOS
      ec2.apply(definition)
      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :tcp, 80)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:tcp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32', '127.0.0.3/32'])
    end

    it 'revokes old udp ingresses' do
      # setup the initial group definition
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80, '127.0.0.1/32', '127.0.0.2/32'
        end
      EOS
      ec2.apply(definition)
      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :udp, 80)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:udp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32', '127.0.0.2/32'])

      # change it
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          udp 80, '127.0.0.1/32', '127.0.0.3/32'
        end
      EOS
      ec2.apply(definition)
      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :udp, 80)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:udp)
      expect(perm.port_range).to eq(80..80)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32', '127.0.0.3/32'])
    end

    it 'revokes old icmp ingresses' do
      # setup the initial group definition
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          icmp '127.0.0.1/32', '127.0.0.2/32'
        end
      EOS
      ec2.apply(definition)
      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :icmp, 0)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:icmp)
      expect(perm.port_range).to eq(0..0)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32', '127.0.0.2/32'])

      # change it
      definition = dsl_eval <<-EOS
        group 'holepunch' do
          icmp '127.0.0.1/32', '127.0.0.3/32'
        end
      EOS
      ec2.apply(definition)
      group = ec2_group(region, 'holepunch')
      perm = ec2_group_ingress(group, :icmp, 0)
      expect(group.ingress_ip_permissions.count).to eq(1)
      expect(perm.protocol).to eq(:icmp)
      expect(perm.port_range).to eq(0..0)
      expect(perm.groups).to be_empty
      expect(perm.ip_ranges).to eq(['127.0.0.1/32', '127.0.0.3/32'])
    end

    it 'raises an error if a dependency does not exist' do
      definition = dsl_eval <<-EOS
        depends 'holepunch-does-not-exist'
      EOS
      expect {
        ec2.apply(definition)
      }.to raise_error(GroupDoesNotExistError)

      group = ec2_group(region, 'holepunch-does-not-exist')
      expect(group).to be_nil
    end
  end
end
