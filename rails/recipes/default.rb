
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

# Install Ruby 1.9.2 and set it as default. Use system-wide RVM.
require_recipe 'git'

package 'curl'

script 'rvm' do
  interpreter 'bash'
  user 'root'
  code <<-EOS
  bash -s stable < <(curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer)
  PATH=$PATH:/usr/local/rvm/bin
  rvm install #{node[:rails][:ruby_version]}
  rvm use #{node[:rails][:ruby_version]} --default
  EOS
end

script 'gem_install_rails' do
  interpreter 'bash'
  user 'root'
  code <<-EOS
  PATH=/usr/local/rvm/bin:$PATH
  rvm use #{node[:rails][:ruby_version]}
  gem install rails #{node[:rails][:rails_gem_options]}
  EOS
end

node[:rails][:gems].each do |pkg|
  script "gem_install_#{node[:rails][:gems]}" do
    interpreter 'bash'
    user 'root'
    code <<-EOS
    PATH=/usr/local/rvm/bin:$PATH
    rvm use #{node[:rails][:ruby_version]}
    gem install #{pkg}
    EOS
  end
end

