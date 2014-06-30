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

describe HolePunch do
  describe '#service_groups' do
    it 'raises if the file does not exist' do
      expect do
        HolePunch.service_groups('does-not-exist', nil, 'web')
      end.to raise_error(SecurityGroupsFileNotFoundError)
    end

    it 'raises if the service is not defined' do
      set_security_groups_content 'SecurityGroups', <<-EOS
      EOS
      expect do
        HolePunch.service_groups('SecurityGroups', nil, 'web')
      end.to raise_error(ServiceDoesNotExistError)
    end

    it 'properly returns the list of groups for the service' do
      set_security_groups_content 'SecurityGroups', <<-'EOS'
        group 'admin'
        group "#{env}-web"
        service 'web' do
          groups 'admin', "#{env}-web"
        end
      EOS
      groups = HolePunch.service_groups('SecurityGroups', 'prod', 'web')

      expect(groups).to match_array(['admin', 'prod-web'])
    end
  end
end
