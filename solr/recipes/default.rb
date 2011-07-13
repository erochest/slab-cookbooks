
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

require_recipe "java"
require_recipe "tomcat"

case node.platform
when 'ubuntu'
  package 'solr-tomcat' do
    action :install
  end

when 'centos'
  # Urg. No package. Might be easier to just skip the packages for Ubuntu, too,
  # though.

  remote_file '/tmp/apache-solr.tgz' do
    source node[:solr][:download_url]
    action :create
  end

  script 'install_solr' do
    interpreter 'bash'
    user 'root'
    cwd '/tmp'
    action :run
    code <<-EOH
    TOMCAT6_DIR=#{node[:tomcat][:webapp_dir]}
    SOLR_DIR=#{node[:solr][:solr_dir]}
    tar xfz apache-solr.tgz
    mv apache-solr-* $SOLR_DIR
    mkdir -p $SOLR_DIR/site/data
    cp -r $SOLR_DIR/example/solr/conf $SOLR_DIR/site/
    cp $SOLR_DIR/dist/*.war $SOLR_DIR/site/apache-solr.war
    EOH
  end

  template "#{node[:solr][:solr_dir]}/site/conf/solrconfig.xml" do
    source 'solrconfig.xml.erb'
    owner 'root'
    mode '0755'
    action :create
  end

  template "#{node[:tomcat][:context_dir]}/solr.xml" do
    source 'solr-context.xml.erb'
    owner 'root'
    mode '0755'
    action :create
  end

  execute 'chown_site' do
    command "chown -R #{node[:tomcat][:user]}:#{node[:tomcat][:group]} #{node[:solr][:solr_dir]}"
    user 'root'
    cwd '/tmp'
    action :run
  end

end

