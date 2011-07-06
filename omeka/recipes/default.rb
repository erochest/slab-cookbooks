
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by
# applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#
# Author      Eric Rochester <err8n@virginia.edu>
# Copyright   2010 The Board and Visitors of the University of Virginia
# License     http://www.apache.org/licenses/LICENSE-2.0.html Apache 2 License

require_recipe "apache2"
require_recipe "apache2::mod_php5"
require_recipe "apache2::mod_rewrite"
require_recipe "php"
require_recipe "mysql::server"
require_recipe "imagemagick"
require_recipe "git"

omeka_github = 'https://github.com/omeka/Omeka.git'

# Set up the PHP MySQL package.
mysql_pkg = value_for_platform(
    [ "centos", "redhat", "fedora" ] => {"default" => "php53-mysql"}, 
    "default" => "php5-mysql"
  )

package mysql_pkg do
  action :install
end

case node.platform
when "centos"
  package "php53-xml" do
    action :install
  end
end

# Set up the Omeka database.
mysql_database "create-omeka-db" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "CREATE DATABASE #{node[:omeka]['mysql_db']} CHARACTER SET = 'utf8' COLLATE = 'utf8_unicode_ci';"
  action    :query
end

if node[:omeka][:test_db] != node[:omeka][:mysql_db]
  mysql_database "create-omeka-test-db" do
    host      "localhost"
    username  "root"
    password  node['mysql']['server_root_password']
    database  "mysql"
    sql       "CREATE DATABASE #{node[:omeka][:test_db]} CHARACTER SET = 'utf8' COLLATE = 'utf8_unicode_ci';"
    action    :query
  end
end

mysql_database "create-omeka-user-local" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "CREATE USER '#{node[:omeka][:mysql_user]}'@'localhost' IDENTIFIED BY '#{node[:omeka][:mysql_password]}';"
  action    :query
end

mysql_database "create-omeka-user-remote" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "CREATE USER '#{node[:omeka][:mysql_user]}'@'%' IDENTIFIED BY '#{node[:omeka][:mysql_password]}';"
  action    :query
end

mysql_database "grant-omeka-user-local" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "GRANT ALL PRIVILEGES ON #{node[:omeka][:mysql_db]}.* TO '#{node[:omeka][:mysql_user]}'@'localhost';"
  action    :query
end

mysql_database "grant-omeka-user-remote" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "GRANT ALL PRIVILEGES ON #{node[:omeka][:mysql_db]}.* TO '#{node[:omeka][:mysql_user]}'@'%';"
  action    :query
end

if node[:omeka][:test_user] != node[:omeka][:mysql_user]

  mysql_database "create-omeka-user-local" do
    host      "localhost"
    username  "root"
    password  node['mysql']['server_root_password']
    database  "mysql"
    sql       "CREATE USER '#{node[:omeka][:test_user]}'@'localhost' IDENTIFIED BY '#{node[:omeka][:test_password]}';"
    action    :query
  end

  mysql_database "create-omeka-user-remote" do
    host      "localhost"
    username  "root"
    password  node['mysql']['server_root_password']
    database  "mysql"
    sql       "CREATE USER '#{node[:omeka][:test_user]}'@'%' IDENTIFIED BY '#{node[:omeka][:test_password]}';"
    action    :query
  end

end

if node[:omeka][:test_user] != node[:omeka][:mysql_user] or node[:omeka][:test_db] != node[:omeka][:mysql_db]

  mysql_database "grant-omeka-user-local" do
    host      "localhost"
    username  "root"
    password  node['mysql']['server_root_password']
    database  "mysql"
    sql       "GRANT ALL PRIVILEGES ON #{node[:omeka][:test_db]}.* TO '#{node[:omeka][:test_user]}'@'localhost';"
    action    :query
  end

  mysql_database "grant-omeka-user-remote" do
    host      "localhost"
    username  "root"
    password  node['mysql']['server_root_password']
    database  "mysql"
    sql       "GRANT ALL PRIVILEGES ON #{node[:omeka][:test_db]}.* TO '#{node[:omeka][:test_user]}'@'%';"
    action    :query
  end

end

## Set up Omeka
# Download Omeka, maybe.
if node[:omeka][:version] != nil then
  omeka_version = node[:omeka][:version]
  omeka_version = 'master' if omeka_version == 'HEAD'

  # If on CentOS, we have to update the SSL certificates manually. Yum. Yeah.
  if node.platform == 'centos'
    script "update_ssl_certificates" do
      interpreter "bash"
      user "root"
      cwd "/etc/pki/tls/certs"
      code <<-EOH
      if [ ! -d /root/backups/ ] ; then
        mkdir -p /root/backups/
      fi
      mv ca-bundle.crt /root/backups/ca-bundle.crt
      curl http://curl.haxx.se/ca/cacert.pem -o /etc/pki/tls/certs/ca-bundle.crt
      EOH
    end
  end

  if File.directory?(node[:omeka][:omeka_dir])
    script "backup_existing_omeka_dir" do
      interpreter "bash"
      user "root"
      cwd "/vagrant"
      code "mv #{node[:omeka][:omeka_dir]} #{node[:omeka][:omeka_dir]}.bk"
    end
  end

  if omeka_version =~ /^[\d\.]*$/ then
    omeka_ref = "tags/" + omeka_version
  else
    omeka_ref = omeka_version
  end

  git node[:omeka][:omeka_dir] do
    repository omeka_github
    reference omeka_ref
    action :checkout
  end
end

# Create the Omeka DB settings file.
template "#{node[:omeka][:omeka_dir]}/db.ini" do
  source "db.ini.erb"
  owner "root"
  group "root"
  mode 0644
end

# Create the Omeka test settings file.
template "#{node[:omeka][:omeka_dir]}/application/tests/config.ini" do
  source "config.ini.erb"
  owner "root"
  group "root"
  mode 0644
end

# Patch Omeka to work around problems with port forwarding and setting up the site.
cookbook_file "#{node[:omeka][:omeka_dir]}/application/models/Installer/Requirements.php" do
  source "Requirements.php"
  mode 0644
end

##
# Set up the site in Apache.
template "#{node[:apache][:dir]}/sites-available/default" do
  source "default-site.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "apache2")
end

# Set up PHP packages.
php_pear_channel "pear.php.net" do
  action :update
end

phpunit = php_pear_channel "pear.phpunit.de" do
  action :discover
end

php_pear_channel "components.ez.no" do
  action :discover
end

php_pear_channel "pear.symfony-project.com" do
  action :discover
end

phpmd = php_pear_channel "pear.phpmd.org" do
  action :discover
end

php_pear_channel "pear.pdepend.org" do
  action :discover
end

php_pear "PEAR" do
  action    :upgrade
  options   "--force"
end

php_pear "PhpDocumentor" do
  action :install
end

php_pear "PHPUnit" do
  channel          phpunit.channel_name

  # Have to change perferred state here because XML_RPC2 now requires
  # HTTP_Request2, which has no stable releases.
  preferred_state  "beta"

  action           :install
end

php_pear "phpcpd" do
  channel   phpunit.channel_name
  action    :install
end

php_pear "PHP_PMD" do
  channel   phpmd.channel_name
  version   "alpha"
  action    :install
end

php_pear "PHP_CodeSniffer" do
  version  "1.3.0a1"
  action   :install
end

script "pecl/xdebug" do
  # OMG, this seems more painful than necessary. There's no php53-* package for
  # CentOS, and just a simple 'pecl install' doesn't work either.

  interpreter "bash"
  user "root"
  cwd "/tmp"

  code <<-EOH
  mkdir xdebug-install
  cd xdebug-install
  pecl download xdebug
  tar xfz *.tgz
  cd $(find . -type d -and -name 'xdebug*')
  phpize
  ./configure
  make
  make install
  echo 'zend_extension="/usr/lib/php/modules/xdebug.so"' > /etc/php.d/xdebug.ini
  EOH
end


