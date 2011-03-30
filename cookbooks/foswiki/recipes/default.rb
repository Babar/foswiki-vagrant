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

%w{ Release01x01 trunk }.each do |branch|
  rootdir = "/home/foswiki/#{branch}"
  git rootdir do
    user "foswiki"
    repository "/vagrant_foswiki"
    reference branch
    action [ :checkout, :sync ]
  end

  logfile="/tmp/UnitTest-#{branch}.log"
  bash "run_unitTests" do
    user "foswiki"
    cwd "#{rootdir}/core"
    code <<-EoC
exec > #{logfile}
exec 2>&1
git clean -xdf
perl -T pseudo-install.pl -A developer
cd test/unit
perl -T ../bin/TestRunner.pl -clean FoswikiSuite.pm
#perl -T ../bin/TestRunner.pl -clean -log Fn_SEARCH::verify_date_param_ForkingSearch
#perl -T ../bin/TestRunner.pl -clean QueryTests
perl -T pseudo-install.pl -u -A developer
exec >&- # Close logfile
EoC
    returns [ 0, 1, 2 ] # Chef shall not fail here, we will check the result manually
    not_if do File.exists?( logfile ) end
  end

  log "Failed: #{branch} => " << `perl -nle'print if /^Unit test run Summary:/ .. /test cases passed/' #{logfile}` do
    level :error
    not_if "grep -q 'All tests passed' #{logfile}"
  end

  log "Passed: #{branch} => " << `grep 'All tests passed' #{logfile}` do
    only_if "grep -q 'All tests passed' #{logfile}"
  end

end
