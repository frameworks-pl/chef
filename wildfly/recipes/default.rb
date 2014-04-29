#
# Cookbook Name:: wildfly
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#


#Create WildFly System user
user 'wildfly' do
  comment 'WildFly'
  shell '/bin/bash'
  supports manage_home: true
  action [:create, :lock]
end

#Create WildFly Group
group 'wildfly' do
  append true
  members 'wildfly'
  action :create
end

# Download WildFly tarball
remote_file "Download and install WildFly" do
  source node['wildfly']['url']
  path "/root/temp/wildfly-8.0.0.Final.tar.gz"
  notifies :run, "execute[Unpack and install WildFly]", :immediately
end

execute "Unpack and install WildFly" do
  command "tar -xvzf wildfly-8.0.0.Final.tar.gz -C /opt" 
  action :run
  cwd "/root"
end


