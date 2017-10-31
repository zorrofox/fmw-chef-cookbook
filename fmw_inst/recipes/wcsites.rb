#
# Cookbook Name:: fmw_inst
# Recipe:: wcsites
#
# Copyright 2015 Oracle. All Rights Reserved
# log  "####{cookbook_name}::#{recipe_name} #{Time.now.inspect}: Starting execution phase"
puts "####{cookbook_name}::#{recipe_name} #{Time.now.inspect}: Starting compile phase"

include_recipe 'fmw_wls::install'

fail 'fmw_inst attributes cannot be empty' unless node.attribute?('fmw_inst')

if node['fmw'].nil?
   node.override['fmw']=Hash.new()
end

if !('typical'.casecmp(node['fmw']['install_type'].to_s)==0)
   node.override['fmw']['install_type']='typical'
end

if ['12.2.1', '12.2.1.1', '12.2.1.2'].include?(node['fmw']['version'])
  fmw_template = 'fmw_12c.rsp'
  fmw_oracle_home = node['fmw']['middleware_home_dir'] + '/wcsite'
  option_array = []
  install_type = 'WebCenter Sites'

  if node['fmw']['version'] == '12.2.1'
    fmw_installer_file = node['fmw']['tmp_dir'] + '/wcsites/fmw_12.2.1.0.0_wcsites_generic.jar'
  elsif node['fmw']['version'] == '12.2.1.1'
    fmw_installer_file = node['fmw']['tmp_dir'] + '/wcsites/fmw_12.2.1.1.0_wcsites.jar'
  elsif node['fmw']['version'] == '12.2.1.2'
    fmw_installer_file = node['fmw']['tmp_dir'] + '/wcsites/fmw_12.2.1.2.0_wcsites.jar'
  end

elsif ['10.3.6'].include?(node['fmw']['version'])
  fmw_template = 'fmw_11g.rsp'
  fmw_oracle_home = node['fmw']['middleware_home_dir'] + '/Oracle_WC1'
  install_type = ''
  option_array = ['APPSERVER_TYPE=WLS',
                  "APPSERVER_LOCATION=#{node['fmw']['middleware_home_dir']}"]

  if node['os'].include?('windows')
    fmw_installer_file = node['fmw']['tmp_dir'] + '/wcsites/Disk1/setup.exe'
  else
    fmw_installer_file = node['fmw']['tmp_dir'] + '/wcsites/Disk1/runInstaller'
  end
end

if node['os'].include?('windows')
  unix = false
else
  unix = true
end

template node['fmw']['tmp_dir'] + '/wc_' + fmw_template do
  source fmw_template
  mode 0755                                                           if unix
  owner node['fmw']['os_user']                                        if unix
  group node['fmw']['os_group']                                       if unix
  variables(middleware_home_dir: node['fmw']['middleware_home_dir'],
            oracle_home: fmw_oracle_home,
            install_type: install_type,
            option_array: option_array)
end

fmw_inst_fmw_extract 'wcsites' do
  action              :extract
  source_file         node['fmw_inst']['wcsites_source_file']
  source_2_file       node['fmw_inst']['wcsites_source_2_file']   if node['fmw_inst'].attribute?('wcsites_source_2_file')
  os_user             node['fmw']['os_user']                      if unix
  os_group            node['fmw']['os_group']                     if unix
  tmp_dir             node['fmw']['tmp_dir']
  version             node['fmw']['version']                      unless unix
  middleware_home_dir node['fmw']['middleware_home_dir']          unless unix
end

if platform_family?('rhel')
  first_run_file = "#{node['fmw']['tmp_dir']}/yumgetrun"
  if ( !::File.exist?(first_run_file) )
    e = bash 'yum-update' do
      code <<-EOH
  yum update
  touch #{first_run_file}
      EOH
      ignore_failure true
      action :nothing
    end
    e.run_action(:run)
  end
end

if platform?('linux')
  package ["libaio-devel", "ksh", "compat-libcap1", "compat-libstdc++-33"] do
    ignore_failure true
    action :install
  end
end

if platform_family?('rhel')
  yum_package ["libaio-devel", "ksh", "compat-libcap1", "glibstdc++", "glibc", "libgcc", "compat-libstdc++-33"] do
    arch 'x86_64'
    ignore_failure true
    action :install
  end
  if node['platform_version'].to_f < 7.0
    yum_package ["libstdc++","glibc", "libgcc", "compat-libstdc++-33"] do
      arch 'i686'
      ignore_failure true
      action :install
    end
  end
end

fmw_inst_fmw_install 'wcsites' do
  action              :install
  java_home_dir       node['fmw']['java_home_dir']
  installer_file      fmw_installer_file
  rsp_file            node['fmw']['tmp_dir'] + '/wc_' + fmw_template
  version             node['fmw']['version']
  oracle_home_dir     fmw_oracle_home
  orainst_dir         node['fmw']['orainst_dir']                     if unix
  os_user             node['fmw']['os_user']                         if unix
  os_group            node['fmw']['os_group']                        if unix
  tmp_dir             node['fmw']['tmp_dir']
end

# log  "####{cookbook_name}::#{recipe_name} #{Time.now.inspect}: Finished execution phase"
puts "####{cookbook_name}::#{recipe_name} #{Time.now.inspect}: Finished compile phase"
