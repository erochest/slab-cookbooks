
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

require 'uri'

download_uri = URI::parse(node.geoserver.download_url)
war_filename = File.basename(download_uri.path)

# Download the file.
remote_file "/tmp/#{war_filename}" do
  source node.geoserver.download_url
  action :create
end

# Unzip it (if a zip file).
if node.geoserver.download_url.downcase.end_with?('.zip')
  package 'unzip'

  script 'unzip-geoserver-download' do
    interpreter 'bash'
    user 'root'
    cwd '/tmp'
    action :run
    code <<-EOH
    mkdir geoserver
    cd geoserver
    unzip ../#{war_filename}
    EOH

    # This is standard.
    war_filename = 'geoserver/geoserver.war'
  end

end

# Deploy the war file. At this point, /tmp/#{war_filename} should point to that
# file.
execute 'cp-geoserver-war' do
  command "cp /tmp/#{war_filename} #{node.tomcat.webapp_dir}/#{node.geoserver.prefix}.war"
  user 'root'
  action :run
  notifies :restart, resources(:service => "tomcat")
end

