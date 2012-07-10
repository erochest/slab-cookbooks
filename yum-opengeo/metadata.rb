
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

name              'yum-opengeo'
version           '0.1'
depends           []
description       'Installs a repostiory for yum.opengeo.org, or nothing.'
maintainer        'Eric Rochester'
maintainer_email  'err8n@virginia.edu'
license           'Apache 2.0'

%w{ redhat centos ubuntu debian }.each do |os|
  supports os
end
