#
# Cookbook Name:: wildfly
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#Create WildFly System user
user 'jboss' do
  comment 'JBoss'
  shell '/bin/bash'
  supports manage_home: true
  action [:create, :lock]
end


#Create WildFly Group
group 'jboss' do
  append true
  members 'jboss'
  action :create
end


# Download WildFly tarball
remote_file "Download and install WildFly" do
  source node['wildfly']['url']
  path "/root/" + node['wildfly']['remote_filename']
  #notifies :run, "execute[Unpack and install WildFly]", :immediately
end


execute "Unpack and install WildFly" do
  command "tar -xvzf " + node['wildfly']['remote_filename'] + " -C /opt --transform s/" + node['wildfly']['release_name'] + "/wildfly/" 
  action :run
  cwd "/root"
end


execute "Change ownership of wildfly installation" do
    command "chown jboss:jboss -R /opt/wildfly"
    action :run
    cwd '/'
end


#Create startup script
template File.join('etc', 'init.d', 'wildfly') do
  source 'wildfly-initd-centos.sh.erb'
  user 'root'
  group 'root'
  mode '0755'
end

# Start the Wildfly Service
service 'wildfly' do
  action :start
end



