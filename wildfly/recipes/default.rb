#
# Cookbook Name:: wildfly
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#By default java cookbook isntalls version 6, WildFly needs 7
node.default['java']['jdk_version'] = '7'

include_recipe "java"
#include_recipe "mysql::server"
#include_recipe "simple_iptables"

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


#------------------------------------------Jenkins support------------------------------------------

#Create jenkins user
user 'jenkins' do
  comment 'Jenkins'
  shell '/bin/bash'
  supports manage_home: true
  action [:create]
end


#Add user jenkins to group jboss
execute "Add user jenkins to group jboss" do
    command "usermod -a -G jboss jenkins"
    action :run
    cwd "/"
end

#Create .ssh directory for jenkins
directory '/home/jenkins/.ssh' do
    owner 'jenkins'
    group 'jenkins'
    mode 0700
    action :create    
end


#Copy public key to jenkins home
template File.join('home', 'jenkins', '.ssh', 'jenkins_rsa.pub') do
  source 'jenkins_rsa.pub'
  user 'jenkins'
  group 'jenkins'
  mode '0600'
end

#Copy jenkins public key to authorized_keys
execute "Copy jenkins public key to authorized_keys" do
  command "cat jenkins_rsa.pub >> authorized_keys"  
  action :run
  cwd "/home/jenkins/.ssh"
end

#Set proper ownership of authorized_keys
execute "Make sure jenkins is owner of his authorized_keys" do
  command "chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys"
  action :run
  cwd "/home/jenkins/.ssh"
end

#Set proper access rights for authorized_keys
execute "Change access rights for /home/jenkins/.ssh/authozied_keys" do
  command "chmod 600 /home/jenkins/.ssh/authorized_keys"
  action :run
  cwd "/home/jenkins/.ssh"
end 

#------------------------------------------Jenkins support------------------------------------------


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


execute "Change ownership of WildFly installation" do
    command "chown jboss:jboss -R /opt/wildfly"
    action :run
    cwd '/'
end

execute "Change access rights for WildFly installation" do
    command "chmod 770 -R /opt/wildfly"
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

#simple_iptables_rule "wildfly on port 8080" do
#  rule "--proto tcp --dport 8080"
#  jump "ACCEPT"
#  chain "INPUT"
#end

#simple_iptables_rule "wildfly on port 9990" do
#  rule "--proto tcp --dport 9990"
#  jump "ACCEPT"
#  chain "INPUT"
#end

# Start the Wildfly Service
service 'wildfly' do
  action :start
end



