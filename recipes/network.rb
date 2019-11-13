#
# Cookbook:: openstack-container
# Recipe:: network
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
include_recipe 'build-essential'
include_recipe 'git'

venv = node['openstack']['container-network']['virtualenv']

execute "virtualenv #{venv}" do
  creates venv
end

# define secrets that are needed in the kuryr.conf
node.default['openstack']['container-network']['conf_secrets'].tap do |conf_secrets|
  conf_secrets['neutron']['password'] = get_password 'service', 'openstack-container-network'
end

identity_endpoint = internal_endpoint 'identity'
auth_url = ::URI.decode identity_endpoint.to_s

node.default['openstack']['container-network']['conf'].tap do |conf|
  conf['neutron']['auth_url'] = auth_url
  conf['neutron']['www_authenticate_uri'] = auth_url
end

kuryr_dir = ::File.join(Chef::Config[:file_cache_path], 'kuryr-libnetwork')

group node['openstack']['container-network']['group'] do
  system true
end

user node['openstack']['container-network']['user'] do
  home '/var/lib/kuryr'
  manage_home true
  system true
  shell '/bin/false'
  gid node['openstack']['container-network']['group']
end

execute 'kuryr deps' do
  command "#{venv}/bin/pip install -I -r requirements.txt"
  cwd ::File.join(kuryr_dir)
  action :nothing
end

execute 'kuryr install' do
  command "#{venv}/bin/python setup.py install"
  cwd ::File.join(kuryr_dir)
  action :nothing
end

git kuryr_dir do
  revision node['openstack']['container-network']['release']
  repository node['openstack']['container-network']['repository']
  notifies :run, 'execute[kuryr deps]', :immediately
  notifies :run, 'execute[kuryr install]', :immediately
end

%w(/etc/kuryr /var/lib/kuryr).each do |d|
  directory d do
    user node['openstack']['container-network']['user']
    group node['openstack']['container-network']['group']
  end
end

# merge all config options and secrets to be used in the zun.conf
kuryr_conf_options = merge_config_options 'container-network'

template node['openstack']['container-network']['conf_file'] do
  source 'openstack-service.conf.erb'
  cookbook 'openstack-common'
  owner node['openstack']['container-network']['user']
  group node['openstack']['container-network']['group']
  variables(
    service_config: kuryr_conf_options
  )
end

cookbook_file '/usr/lib/docker/plugins/kuryr/kuryr.json'

systemd_unit 'kuryr-libnetwork.service' do
  content node['openstack']['container']['network']['unit']
  action [:create, :enable, :start]
end

service 'kuryr-libnetwork' do
  action [:enable, :start]
  subscribes :restart, "template[#{node['openstack']['container-network']['conf_file']}]"
end
