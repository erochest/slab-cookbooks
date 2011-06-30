
maintainer "Eric Rochester"
maintainer_email "err8n@virginia.edu"
license "Apache 2.0"
description "Installs and configures Omeka."
version "0.0.1"

depends "apache2"
depends "php"
depends "mysql"
depends "imagemagick"

%w{ centos }.each do |os|
  supports os
end

recipe "omeka", "Installs and configures Omeka."

