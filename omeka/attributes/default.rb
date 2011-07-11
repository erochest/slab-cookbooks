
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

default[:omeka][:omeka_dir]      = '/vagrant/omeka'
default[:omeka][:version]        = nil
default[:omeka][:themes]         = []
default[:omeka][:plugins]        = []

default[:omeka][:mysql_user]     = 'omeka'
default[:omeka][:mysql_password] = 'omeka'
default[:omeka][:mysql_db]       = 'omeka'
default[:omeka][:mysql_prefix]   = 'omeka_'

default[:omeka][:test_user]      = 'omeka'
default[:omeka][:test_password]  = 'omeka'
default[:omeka][:test_db]        = 'omeka'

