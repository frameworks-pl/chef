#
# Cookbook Name:: wildfly
# Recipe:: default
#
# janusz.grabis@vgw.co

#By default java cookbook isntalls version 6, WildFly needs 7
node.default['java']['jdk_version'] = '7'
include_recipe 'java'

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

#Replace standalone configuration file
template '/opt/wildfly/standalone/configuration/standalone.xml' do
  source 'standalone.xml.erb'
  user 'jboss'
  group 'jboss'
  mode '0770'
end

#Install MySQL Connector driver
cookbook_file "/opt/wildfly/modules/system/layers/base/com/mysql/main/mysql-connector-java-5.1.30-bin.jar" do
  source "mysql-connector-java-5.1.30-bin.jar"
  mode 0755
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


# Start the Wildfly Service
service 'wildfly' do
  action :start
end


#Add/update WildFly admin user (password needs to be changed manually!!!)
execute "Set up WildFly admin user" do
  command "/opt/wildfly/bin/add-user.sh admin admin --silent=true"
  action :run
  cwd '/'
end
