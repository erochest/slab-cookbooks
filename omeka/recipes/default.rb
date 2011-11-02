
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

# May need to update the package index first.
case node.platform
when "ubuntu", "debian"
  require_recipe 'apt'
when "centos", "redhat", "fedora"
  package 'yum-utils'
  execute 'remove-elff-repos' do
    command 'mv /etc/yum.repos.d/elff*.repo /tmp/'
    user 'root'
  end
end

require_recipe "apache2"
require_recipe "apache2::mod_php5"
require_recipe "apache2::mod_rewrite"
require_recipe "php"
require_recipe "php::module_curl"
require_recipe "mysql::server"
require_recipe "imagemagick"
require_recipe "git"
require_recipe "subversion"

require 'fileutils'

default_themes = [
  {:name => 'minimalist',     :url => 'git://github.com/omeka/theme-minimalist.git'},
  {:name => 'rhythm',         :url => 'git://github.com/omeka/theme-rhythm.git'},
  {:name => 'seasons',        :url => 'git://github.com/omeka/theme-seasons.git'}
]
default_plugins = [
  {:name => 'Coins',          :url => 'git://github.com/omeka/plugin-Coins.git'},
  {:name => 'ExhibitBuilder', :url => 'git://github.com/omeka/plugin-ExhibitBuilder.git'},
  {:name => 'SimplePages',    :url => 'git://github.com/omeka/plugin-SimplePages.git'}
]

# Set up the PHP MySQL package.
mysql_pkg = value_for_platform(
    [ "centos", "redhat", "fedora" ] => {"default" => "php53-mysql"}, 
    "default" => "php5-mysql"
  )

package mysql_pkg do
  action :install
end

gem_package 'mysql' do
  action :install
end

case node.platform
when "centos"
  package "php53-xml" do
    action :install
  end
end

# Set up the Omeka database.
template '/tmp/create_omeka_db.sql' do
  source 'create_omeka_db.sql.erb'
  action :create
end

execute 'create-omeka-db' do
  command "mysql -hlocalhost -uroot -p#{node[:mysql][:server_root_password]} mysql < /tmp/create_omeka_db.sql"
  action  :run
end

## Set up Omeka
# Download Omeka, maybe.
if node[:omeka][:version] != nil then
  omeka_version = node[:omeka][:version]
  omeka_version = 'master' if omeka_version == 'HEAD'

  # If on CentOS, we have to update the SSL certificates manually. Yum. Yeah.
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
    only_if do
      node.platform == 'centos'
    end
  end

  script "backup_existing_omeka_dir" do
    interpreter "bash"
    user "root"
    cwd "/vagrant"
    code "mv #{node[:omeka][:omeka_dir]} #{node[:omeka][:omeka_dir]}.bk"
    only_if do
      File.directory?(node[:omeka][:omeka_dir])
    end
  end

  if omeka_version =~ /^[\d\.]*$/ then
    omeka_ref = "tags/" + omeka_version
  else
    omeka_ref = omeka_version
  end

  git node[:omeka][:omeka_dir] do
    repository node.omeka.git
    reference omeka_ref
    enable_submodules true
    action :checkout
  end
end

# This is bad, bad, bad. I need to change the file permissions for directories
# under /vagrant, so I have to unmount it and remount it.
script "set_archive_permissions" do
  interpreter 'bash'
  user 'root'
  cwd '/'

  vm = node[:vagrant][:config][:vm]
  vagrant_dir = node[:vagrant][:directory]
  # TODO: Need to look up the name v-root from vm[:shared_folders] the
  # :guestpath keyed by 'v-root'.

  perms = []
  perms << "uid=`id -u #{vm[:shared_folder_uid]}`" if vm[:shared_folder_uid] != nil
  perms << "gid=`id -g #{vm[:shared_folder_gid]}`" if vm[:shared_folder_uid] != nil
  perms << 'dmode=0777'
  perms = " -o #{perms.join(",")}" if !perms.empty?

  code <<-EOH
  umount #{vagrant_dir}
  mount -t vboxsf#{perms} v-root #{vagrant_dir}
  EOH
  only_if do
    node[:instance_role] == 'vagrant'
  end
end

## Fill in files. This is only necessary on the 
# Copy and fill in *.changeme files.
script "htaccess_changeme" do
  interpreter "bash"
  user "root"
  cwd node[:omeka][:omeka_dir]
  code <<-EOH
  mv .htaccess.changeme .htaccess
  EOH
  not_if do
    File.exists?("#{node[:omeka][:omeka_dir]}/.htaccess")
  end
end

script "config_ini_changeme" do
  interpreter "bash"
  user "root"
  cwd node[:omeka][:omeka_dir]
  code <<-EOH
  mv application/config/config.ini.changeme application/config/config.ini
  EOH
  not_if do
    File.exists?("#{node[:omeka][:omeka_dir]}/application/config/config.ini")
  end
end

ruby_block "tests_config_ini_changeme" do
  action :create
  block do
    subs = {
      "db.host = \"\"\n"     => "db.host = \"localhost\"",
      "db.username = \"\"\n" => "db.username = \"#{node[:omeka][:test_user]}\"",
      "db.password = \"\"\n" => "db.password = \"#{node[:omeka][:test_password]}\"",
      "db.dbname = \"\"\n"   => "db.dbname = \"#{node[:omeka][:test_db]}\""
    }

    OmekaUtils.sed(
      "#{node[:omeka][:omeka_dir]}/application/tests/config.ini.changeme",
      "#{node[:omeka][:omeka_dir]}/application/tests/config.ini") do |line|
        subs.fetch(line, line)
      end
  end
  not_if do
    File.exists?("#{node[:omeka][:omeka_dir]}/application/tests/config.ini")
  end
end

ruby_block "db_ini_changeme" do
  action :create
  block do
    subs = {
      "host     = \"XXXXXXX\"\n" => "host     = \"localhost\"",
      "username = \"XXXXXXX\"\n" => "username = \"#{node[:omeka][:mysql_user]}\"",
      "password = \"XXXXXXX\"\n" => "password = \"#{node[:omeka][:mysql_password]}\"",
      "dbname   = \"XXXXXXX\"\n" => "dbname   = \"#{node[:omeka][:mysql_db]}\"",
      "prefix   = \"omeka_\"\n"  => "prefix   = \"#{node[:omeka][:mysql_prefix]}\"",
    }
    OmekaUtils.sed(
      "#{node[:omeka][:omeka_dir]}/db.ini.changeme",
      "#{node[:omeka][:omeka_dir]}/db.ini") do |line|
        subs.fetch(line, line)
      end
  end
end

# For some reason, this is making index not redirect to install/ under Lucid.
if node.platform == 'ubuntu'
  ruby_block "options_php_patch" do
    action :create
    block do
      src = "#{node[:omeka][:omeka_dir]}/application/libraries/Omeka/Core/Resource/Options.php"
      tmp = "/tmp/Options.php"
      OmekaUtils.sed(src, tmp) do |line|
        if line.lstrip.start_with?('header(\'Location:')
          line + ' exit;'
        else
          line
        end
      end
      FileUtils.rm(src)
      FileUtils.mv(tmp, src)
    end
  end
end

ruby_block "requirements_patch" do
  action :create
  block do
    src = "#{node[:omeka][:omeka_dir]}/application/models/Installer/Requirements.php"
    tmp = "/tmp/Requirements.php"
    OmekaUtils.sed(src, tmp) do |line|
      line.sub(/(\s+)(\$this->_checkModRewriteIsEnabled\(\);)$/, '\1// \2')
    end
    FileUtils.rm(src)
    FileUtils.mv(tmp, src)
  end
end

# This handles a repository checkout specification (i.e., a Hash with the
# keys :name and :url and maybe :type).
def make_repo_task(node, base_dir, repo)
  target = "#{base_dir}/#{repo[:name]}"

  case repo.fetch(:type, 'git')
  when 'svn'
    subversion target do
      repository    repo[:url]
      action        :checkout
      svn_username  repo.fetch(:svn_username, nil)
      svn_password  repo.fetch(:svn_password, nil)
      svn_arguments " --non-interactive --trust-server-cert --no-auth-cache "
      svn_info_args " --non-interactive --trust-server-cert --no-auth-cache "
    end

  when 'git'
    git target do
      repository repo[:url]
      reference  repo.fetch(:revision, 'master')
      action     :checkout
    end

  else
    raise "Invalid repository type: '#{repo[:type]}'."
  end
end

## Download Themes
node[:omeka][:themes].each do |theme_info|
  make_repo_task(node, "#{node[:omeka][:omeka_dir]}/themes", theme_info)
end

## Download Plug Ins
node[:omeka][:plugins].each do |plugin_info|
  make_repo_task(node, "#{node[:omeka][:omeka_dir]}/plugins", plugin_info)
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
if node.omeka.phptools
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

#   phpunit = php_pear_channel "pear.phpqatools.org" do
#     action :discover
#   end
#   php_pear "PhpDocumentor" do
#     action  :install
#   end

  script 'install-PhpDocumentor' do
    interpreter 'bash'
    user        'root'
    code <<-EOS
    pear config-set auto_discover 1
    pear install pear.phpqatools.org/phpqatools PHPDocumentor
    EOS
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

#   php_pear "PHP_PMD" do
#     channel   phpmd.channel_name
#     version   "alpha"
#     action    :install
#   end

  php_pear "PHP_CodeSniffer" do
    version  "1.3.0"
    action   :install
  end

  case node.platform
  when 'centos'
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

  when 'ubuntu'
    package 'php5-xdebug' do
      action :install
    end
  end
end

# Touch a couple of files so that Apache can write to them later, if necessary.
file "#{node[:omeka][:omeka_dir]}/application/logs/errors.log" do
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
end
file "#{node[:omeka][:omeka_dir]}/application/logs/processes.log" do
  owner  'root'
  group  'root'
  mode   '0755'
  action :create
end


#* `:username` — Default Superuser Account Username *(required)*
#* `:password` — Default Superuser Account Password *(required)*
#* `:super_email` — Default Superuser Account Email *(required)*
#* `:administrator_email` — Site Administrator Email *(required)*
#* `:site_title` — Site Title *(required)*
#* `:description` — Site Description
#* `:copyright` — Site Copyright Information
#* `:author` — Site Author Information
#* `:tag_delimiter` — Tag Delimiter *(default is ',')*
#* `:fullsize_constraint` — Fullsize Image Size *(required, default is 800)*
#* `:thumbnail_constraint` — Thumbnail Size *(required, default is 200)*
#* `:square_thumbnail_constraint` — Square Thumbnail Size *(required, default
#is 200)*
#* `:per_page_admin` — Items Per Page (admin) *(required, default is 10)*
#* `:per_page_public` — Items Per Page (public) *(required, default is 10)*
#* `:show_empty_elements` — Show Empty Elements *(default is false)*
#* `:path_to_convert` — Imagemagick Directory Path *(default is '/usr/bin')*
service 'apache2' do
  action :restart
end

script "omeka_post_install" do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
  wget -O /tmp/install.html --post-data='username=#{OmekaUtils.escape(node[:omeka][:username])}&password=#{OmekaUtils.escape(node[:omeka][:password])}&password_confirm=#{OmekaUtils.escape(node[:omeka][:password])}&super_email=#{OmekaUtils.escape(node[:omeka][:super_email])}&administrator_email=#{OmekaUtils.escape(node[:omeka][:administrator_email])}&site_title=#{OmekaUtils.escape(node[:omeka][:site_title])}&description=#{OmekaUtils.escape(node[:omeka][:description])}&copyright=#{OmekaUtils.escape(node[:omeka][:copyright])}&author=#{OmekaUtils.escape(node[:omeka][:author])}&tag_delimiter=#{OmekaUtils.escape(node[:omeka][:tag_delimiter])}&fullsize_constraint=#{OmekaUtils.escape(node[:omeka][:fullsize_constraint])}&thumbnail_constraint=#{OmekaUtils.escape(node[:omeka][:thumbnail_constraint])}&square_thumbnail_constraint=#{OmekaUtils.escape(node[:omeka][:square_thumbnail_constraint])}&per_page_admin=#{OmekaUtils.escape(node[:omeka][:per_page_admin])}&per_page_public=#{OmekaUtils.escape(node[:omeka][:per_page_public])}&show_empty_elements=#{OmekaUtils.escape(node[:omeka][:show_empty_elements])}&path_to_covert=#{OmekaUtils.escape(node[:omeka][:path_to_covert])}&install_confirm=install_confirm' http://localhost/install/
  EOH
  only_if do
    (node[:omeka][:username] &&
     node[:omeka][:password] && node[:omeka][:password].length >= 6 &&
     node[:omeka][:super_email] && node[:omeka][:administrator_email] &&
     node[:omeka][:site_title])
  end
end

