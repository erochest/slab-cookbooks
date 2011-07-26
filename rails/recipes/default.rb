
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

# First, need to get Ruby 1.9.2. I'm going down to the metal to install this
# into /usr/local from source.

script 'compile_install_ruby' do
  interpreter 'bash'
  user 'root'
  code <<-EOS
  wget -O dl-ruby-stable.tar.gz #{node[:rails][:ruby_url]}
  tar xfz dl-ruby-stable.tar.gz
  cd ruby-*
  ./configure
  make
  make install
  EOS
end

script 'gem_install_rails' do
  interpreter 'bash'
  user 'root'
  code 'gem install rails'
end

node[:rails][:gems].each do |pkg|
  script "gem_install_#{node[:rails][:gems]}" do
    interpreter 'bash'
    user 'root'
    code "gem install #{node[:rails][:gems]}"
  end
end

