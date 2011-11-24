maintainer       "Olivier Raginel"
maintainer_email "wiki@babar.us"
license          "All rights reserved"
description      "Installs/Configures foswiki"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.0.1"

recipe "foswiki", "Installs foswiki"

%w{ apache2 apt git java_sun }.each do |cb|
  depends cb
end

# %w{ ubuntu debian centos rhel arch }.each do |os| # Not there yet
%w{ ubuntu debian }.each do |os|
  supports os
end
