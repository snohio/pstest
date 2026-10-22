#
# Cookbook:: pstest
# Recipe:: default
#
# Copyright:: 2026, Mike, All Rights Reserved.

directory 'C:/chef-pstest'

cookbook_file 'C:/test.ps1' do
  source 'test.ps1'
end

powershell_script 'run C:/test.ps1' do
  code "& 'C:/test.ps1'"
  live_stream true
end
