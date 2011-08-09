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

require_recipe "python"

package "python-mysqldb"

python_pip "Django" do
  action :install
end

unless node[:djangodev][:sqlite].nil?
  # Nothing to do here, really. It is zero-config, after all.
end

unless node[:djangodev][:mysql_db].nil?
  case node.platform
  when 'redhat', 'centos', 'fedora', 'suse'
    devpkg = 'mysql-devel'
  when 'debian', 'ubuntu'
    devpkg = 'libmysqlclient-dev'
  end
  package devpkg do
    action :install
  end

  gem_package 'mysql' do
    action :install
  end

  require_recipe "mysql::server"

  mysql_database "user_#{node[:djangodev][:mysql_user]}@localhost" do
    host       node[:djangodev][:mysql_host]
    username   'root'
    password   node[:mysql][:server_root_password]
    database   'mysql'
    action     :query
    sql        "CREATE USER '#{node[:djangodev][:mysql_user]}'@'localhost' IDENTIFIED BY '#{node[:djangodev][:mysql_password]}';"
  end

  mysql_database "user_#{node[:djangodev][:mysql_user]}" do
    host       node[:djangodev][:mysql_host]
    username   'root'
    password   node[:mysql][:server_root_password]
    database   'mysql'
    action     :query
    sql        "CREATE USER '#{node[:djangodev][:mysql_user]}'@'%' IDENTIFIED BY '#{node[:djangodev][:mysql_password]}';"
  end

  mysql_database "grant_#{node[:djangodev][:mysql_user]}@localhost" do
    host       node[:djangodev][:mysql_host]
    username   'root'
    password   node[:mysql][:server_root_password]
    database   'mysql'
    action     :query
    sql        "GRANT ALL PRIVILEGES ON *.* TO '#{node[:djangodev][:mysql_user]}'@'localhost';"
  end

  mysql_database "grant_#{node[:djangodev][:mysql_user]}" do
    host       node[:djangodev][:mysql_host]
    username   'root'
    password   node[:mysql][:server_root_password]
    database   'mysql'
    action     :query
    sql        "GRANT ALL PRIVILEGES ON *.* TO '#{node[:djangodev][:mysql_user]}'@'%';"
  end

  mysql_database "database_#{node[:djangodev][:mysql_db]}" do
    host       node[:djangodev][:mysql_host]
    username   node[:djangodev][:mysql_user]
    password   node[:djangodev][:mysql_password]
    database   node[:djangodev][:mysql_db]
    action     :create_db
  end
end

node[:djangodev][:pips].each do |pip|
  python_pip pip do
    action :install
  end
end


