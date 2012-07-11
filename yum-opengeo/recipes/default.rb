
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by
# applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#
# Author      Eric Rochester <err8n@virginia.edu>
# Copyright   2011 The Board and Visitors of the University of Virginia
# License     http://www.apache.org/licenses/LICENSE-2.0.html Apache 2 License

case node.platform
when 'redhat', 'centos', 'fedora', 'suse'
  if platform?('redhat')
    repo = 'rhel'
  else
    repo = node.platform
  end
  version = node.platform_version.to_i
  arch = node.kernel.machine =~ /x86_64/ ? "x86_64" : "i386"

  yum_repository 'opengeo' do
    name 'OpenGeo'
    url  "http://yum.opengeo.org/#{repo}/#{version}/#{arch}/"
    action :add
  end
end

