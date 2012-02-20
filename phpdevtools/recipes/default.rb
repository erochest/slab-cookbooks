
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
require_recipe "php"
require_recipe "php::module_curl"

require 'fileutils'

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

phpunit = php_pear_channel "pear.phpqatools.org" do
  action :discover
end
php_pear "PhpDocumentor" do
  action  :install
  only_if{ node[:phpdevtools][:phpdocumentor] }
end

script 'install-PhpDocumentor' do
  interpreter 'bash'
  user        'root'
  code <<-EOS
  pear config-set auto_discover 1
  pear install pear.phpqatools.org/phpqatools PHPDocumentor
  EOS
  only_if{ node[:phpdevtools][:phpdocumentor] }
end

php_pear "PHPUnit" do
  channel          phpunit.channel_name

  # Have to change perferred state here because XML_RPC2 now requires
  # HTTP_Request2, which has no stable releases.
  preferred_state  "beta"

  action           :install
  only_if         { node[:phpdevtools][:phpunit] }
end

php_pear "phpcpd" do
  channel   phpunit.channel_name
  action    :install
  only_if  { node[:phpdevtools][:phpcpd] }
end

php_pear "PHP_PMD" do
  channel   phpmd.channel_name
  version   "alpha"
  action    :install
  only_if  { node[:phpdevtools][:phppmd] }
end

php_pear "PHP_CodeSniffer" do
  version  "1.3.0"
  action   :install
  only_if { node[:phpdevtools][:phpcs] }
end

if node[:phpdevtools][:xdebug]
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

service 'apache2' do
  action :restart
end

