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

  template '/tmp/django_mysql_setup.sql' do
    source 'django_mysql_setup.sql.erb'
    action :create
  end

  execute 'django_mysql_setup' do
    command "mysql -hlocalhost -uroot -p#{node[:mysql][:server_root_password]} mysql < /tmp/django_mysql_setup.sql"
    action  :run
  end

  template '/tmp/django_mysql_create.sql' do
    source 'django_mysql_create.sql.erb'
    action :create
  end

  execute 'django_mysql_create' do
    command "mysql -h#{node[:djangodev][:mysql_host]} -u#{node[:djangodev][:mysql_user]} -p#{node[:djangodev][:mysql_password]} < /tmp/django_mysql_create.sql"
    action  :run
  end
end

node[:djangodev][:pips].each do |pip|
  python_pip pip do
    action :install
  end
end


