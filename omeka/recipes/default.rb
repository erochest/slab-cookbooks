
require_recipe "apache2"
require_recipe "apache2::mod_php5"
require_recipe "apache2::mod_rewrite"
require_recipe "php"
require_recipe "mysql::server"
require_recipe "imagemagick"

node.set_unless[:omeka][:mysql_user]     = 'omeka'
node.set_unless[:omeka][:mysql_password] = 'omeka'
node.set_unless[:omeka][:mysql_db]       = 'omeka'
node.set_unless[:omeka][:mysql_prefix]   = 'omeka_'
node.set_unless[:omeka][:omeka_dir]      = '/vagrant/omeka'

# Set up the PHP MySQL package.
pkg = value_for_platform(
    [ "centos", "redhat", "fedora" ] => {"default" => "php53-mysql"}, 
    "default" => "php5-mysql"
  )

package pkg do
  action :install
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

# Set up the site in Apache.
template "#{node[:apache][:dir]}/sites-available/default" do
  source "default-site.erb"
  owner "root"
  group "root"
  mode 0644
  notifies :restart, resources(:service => "apache2")
end

# Create the Omeka DB settings file.
template "#{node[:omeka][:omeka_dir]}/db.ini" do
  source "db.ini.erb"
  owner "root"
  group "root"
  mode 0644
end

# Patch Omeka to work around problems with port forwarding and setting up the site.
cookbook_file "#{node[:omeka][:omeka_dir]}/application/models/Installer/Requirements.php" do
  source "Requirements.php"
  mode 0644
end

