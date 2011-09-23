
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

require_recipe 'java'
require_recipe 'tomcat'

remote_file '/tmp/geonetwork-installer.jar' do
  source node.geonetwork.installer_url
  action :create
end

cookbook_file '/tmp/geonetwork-installer.xml' do
  source 'geonetwork-installer.xml'
  action :create
end

execute 'install-geonetwork' do
  command 'java -jar /tmp/geonetwork-installer.jar /tmp/geonetwork-installer.xml'
  user 'root'
  action :run
end

script 'install-geoserver-context' do
  interpreter 'python'
  user 'root'
  cwd '/tmp'
  action :run
  code <<-EOH
import os
import sys
from xml.etree import cElementTree as ET
tree = ET.parse('#{node.tomcat.config_dir}/server.xml')
server = tree.getroot()
host = server.find('Service/Engine/Host')
context = ET.SubElement(
    host, 'Context',
    path='/geonetwork',
    docBase='/usr/local/projects/geonetwork/web/geonetwork',
    reloadable='true',
    )
context.tail = '\\n'
os.rename('#{node.tomcat.config_dir}/server.xml', '#{node.tomcat.config_dir}/server.xml.bk')
with open('#{node.tomcat.config_dir}/server.xml', 'w') as f:
    tree.write(f)
EOH
  notifies :restart, resources(:service => 'tomcat')
end

