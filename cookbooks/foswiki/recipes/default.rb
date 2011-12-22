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

passwd_file = "/home/foswiki/.htpasswd"
# Checkout both working branches into separate directories
%w{ Release01x01 master }.each do |branch|
  rootdir = "/home/foswiki/#{branch}"

  # Checkout source code for the branch
  git rootdir do
    user "foswiki"
    repository "/vagrant_foswiki"
    reference branch
    action [ :checkout, :sync ]
  end

  # pseudo-install code
  bash "pseudo_install" do
    user "foswiki"
    cwd "#{rootdir}/core"
    code "perl -T pseudo-install.pl developer"
    not_if do File.exists?( "#{rootdir}/core/build.pl" ) end
  end

  # Install default Apache configuration
  template "#{node[:apache][:dir]}/conf.d/#{branch}.conf" do
    source "apache.erb"
    owner "root"
    group "root"
    mode 0644
    notifies :restart, resources(:service => "apache2")
    variables(
      :branch       => branch,
      :passwd_file  => passwd_file,
      :rootdir      => rootdir
    )
  end

  # Install default Foswiki configuration
  template "#{rootdir}/core/lib/LocalSite.cfg" do
    source "LocalSite.erb"
    owner node[:apache][:user]
    group node[:apache][:user]
    mode 0644
    variables(
      :branch       => branch,
      :passwd_file  => passwd_file,
      :rootdir      => rootdir
    )
    not_if do File.exists?( "#{rootdir}/core/lib/LocalSite.cfg" ) end
  end

  # Create the necessary directories, and ensure apache user can write
  # where he needs to
  %w{ data working pub test/unit/fake_templates test/unit
      test/unit/fake_data lib/Foswiki/Plugins }.each do |dir|
    bash "fix perms #{dir}" do
      code "chown -R #{node[:apache][:user]} #{rootdir}/core/#{dir}"
      only_if do File.exists?( "#{rootdir}/core/#{dir}" ) end
    end
    directory "#{rootdir}/core/#{dir}" do
      recursive true
      owner node[:apache][:user]
      group node[:apache][:user]
      mode "0755"
      action :create
    end
  end

  # Install some useful development scripts
  %w{ bisect build-release dev git run-tests }.each do |file|
    cookbook_file "#{rootdir}/#{file}.sh" do
      source "#{file}.sh"
      owner "vagrant"
      group "vagrant"
      mode 0755
    end
  end
end

# Create the .htpasswd default one: admin / foswiki
bash "Create default .htpasswd" do
  code <<-EoC
    htpasswd -b -c #{passwd_file} admin foswiki
    chown #{node[:apache][:user]} #{passwd_file}
  EoC
  not_if do File.exists?( passwd_file ) end
end
