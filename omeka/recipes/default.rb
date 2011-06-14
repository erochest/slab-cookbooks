
require_recipe "apache2"
require_recipe "apache2::mod_php5"
require_recipe "mysql::server"

node.set_unless['omeka']['mysql_user']     = 'omeka'
node.set_unless['omeka']['mysql_password'] = 'omeka'
node.set_unless['omeka']['mysql_db']       = 'omeka'

mysql_database "create-omeka-user" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "GRANT ALL ON #{node['omeka']['mysql_db']}.* TO '#{node['omeka']['mysql_user']}'@'%' IDENTIFIED BY '#{node['omeka']['mysql_password']}';"
  action    :query
end

mysql_database "create-omeka-db" do
  host      "localhost"
  username  "root"
  password  node['mysql']['server_root_password']
  database  "mysql"
  sql       "CREATE DATABASE #{node['omeka']['mysql_db']} CHARACTER SET = 'utf8' COLLATE = 'utf8_unicode_ci';"
  action    :query
end

