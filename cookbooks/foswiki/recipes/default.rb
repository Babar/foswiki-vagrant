#
# Cookbook Name:: foswiki
# Recipe:: default
#
# Copyright 2011, Babar
#
# All rights reserved - Do Not Redistribute
#

# To clone the sources
include_recipe "git"
package "git-svn"
# For JQuery compression
include_recipe "java_sun"
# Install apache
include_recipe "apache2"
# If you want mod_perl, you can try this:
#include_recipe "apache2::mod_perl"

# Foswiki dependencies
%w{ libdevel-symdump-perl libhtml-tidy-perl libhtml-tree-perl
    libhtml-parser-perl liburi-perl libwww-perl tidy zip
    libcss-minifier-xs-perl libjavascript-minifier-xs-perl
    liberror-perl libalgorithm-diff-perl rcs }.each do |pkg|
  package pkg
end

user "foswiki" do
  comment "Foswiki Application user"
  shell "/bin/bash"
  home "/home/foswiki"
end

directory "/home/foswiki" do
  action :create
  owner "foswiki"
  recursive true
end

# Checkout both working branches into separate directories
%w{ Release01x01 master }.each do |branch|
  rootdir = "/home/foswiki/#{branch}"
  git rootdir do
    user "foswiki"
    repository "/vagrant_foswiki"
    reference branch
    action [ :checkout, :sync ]
  end

  bash "pseudo_install" do
    user "foswiki"
    cwd "#{rootdir}/core"
    code "perl -T pseudo-install.pl -A developer"
    not_if do File.exists?( "#{rootdir}/core/lib/LocalSite.cfg" ) end
  end
end
