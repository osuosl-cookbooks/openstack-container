#
# Cookbook:: openstack-container
# Recipe:: common
#
# Copyright:: 2019, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ::Chef::Recipe
  include ::Openstack
end

include_recipe 'openstack-common'

build_essential 'openstack-container-common'

include_recipe 'git'

# Clear lock file when notified
execute 'Clear zun apache restart' do
  command "rm -f #{Chef::Config[:file_cache_path]}/zun-apache-restarted"
  action :nothing
end

venv = node['openstack']['container']['virtualenv']

execute "virtualenv #{venv}" do
  creates venv
end

execute "#{venv}/bin/pip install PyMySQL" do
  creates "#{venv}/lib/python2.7/site-packages/pymysql"
end

package node['openstack']['container']['zunclient_packages']

execute 'install python-zunclient' do
  command "/usr/bin/pip install python-zunclient==#{node['openstack']['container']['zunclient_version']}"
  creates '/usr/lib/python2.7/site-packages/zunclient'
end

package node['openstack']['container']['packages']

db_type = node['openstack']['db']['container']['service_type']
node['openstack']['db']['python_packages'][db_type].each do |pkg|
  package pkg do
    action :upgrade
  end
end

if node['openstack']['mq']['service_type'] == 'rabbit'
  node.default['openstack']['container']['conf_secrets']['DEFAULT']['transport_url'] = rabbit_transport_url 'container'
end

db_user = node['openstack']['db']['container']['username']
db_pass = get_password 'db', 'zun'
container_service = node['openstack']['bind_service']['all']['container']
container_service_address = bind_address container_service
container_docker_service = node['openstack']['bind_service']['all']['container-docker']
container_docker_service_address = bind_address container_docker_service
container_etcd_service = node['openstack']['bind_service']['all']['container-etcd']
container_etcd_service_address = bind_address container_etcd_service

# define secrets that are needed in the zun.conf
node.default['openstack']['container']['conf_secrets'].tap do |conf_secrets|
  conf_secrets['database']['connection'] = db_uri('container', db_user, db_pass)
  conf_secrets['keystone_auth']['password'] = get_password 'service', 'openstack-container'
  conf_secrets['keystone_authtoken']['password'] = get_password 'service', 'openstack-container'
end

identity_endpoint = internal_endpoint 'identity'
auth_url = ::URI.decode identity_endpoint.to_s

node.default['openstack']['container']['conf'].tap do |conf|
  conf['api']['host'] = container_service_address
  conf['api']['port'] = container_service['port']
  conf['keystone_authtoken']['auth_url'] = auth_url
  conf['keystone_authtoken']['www_authenticate_uri'] = auth_url
  conf['keystone_auth']['auth_url'] = auth_url
  conf['keystone_auth']['www_authenticate_uri'] = auth_url
  conf['docker']['docker_remote_api_host'] = container_docker_service_address
  conf['docker']['docker_remote_api_port'] = container_docker_service['port']
  conf['etcd']['etcd_host'] = container_etcd_service_address
  conf['etcd']['etcd_port'] = container_etcd_service['port']
end

zun_dir = ::File.join(Chef::Config[:file_cache_path], 'zun')

group node['openstack']['container']['group'] do
  system true
end

user node['openstack']['container']['user'] do
  home '/var/lib/zun'
  manage_home true
  system true
  shell '/bin/false'
  gid node['openstack']['container']['group']
end

execute 'zun deps' do
  command "#{venv}/bin/pip install -I -r requirements.txt"
  cwd ::File.join(zun_dir)
  action :nothing
end

execute 'zun install' do
  command "#{venv}/bin/python setup.py install"
  cwd ::File.join(zun_dir)
  action :nothing
end

git zun_dir do
  revision node['openstack']['container']['release']
  repository node['openstack']['container']['repository']
  notifies :run, 'execute[zun deps]', :immediately
  notifies :run, 'execute[zun install]', :immediately
end

%w(/etc/zun /var/lib/zun/tmp).each do |d|
  directory d do
    user node['openstack']['container']['user']
    group node['openstack']['container']['group']
    mode '0750'
  end
end

# merge all config options and secrets to be used in the zun.conf
zun_conf_options = merge_config_options 'container'

template node['openstack']['container']['conf_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['container']['user']
  group node['openstack']['container']['group']
  mode '0640'
  variables(
    service_config: zun_conf_options
  )
  notifies :run, 'execute[Clear zun apache restart]', :immediately
end
