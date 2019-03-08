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

include_recipe 'build-essential'
include_recipe 'git'

python_runtime 'osc-zun' do
  version '2'
  provider :system
  pip_version '9.0.3'
end

python_virtualenv node['openstack']['container']['virtualenv'] do
  python 'osc-zun'
  system_site_packages true
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
bind_service = node['openstack']['bind_service']['all']['container']
bind_service_address = bind_address bind_service

# define secrets that are needed in the zun.conf
node.default['openstack']['container']['conf_secrets'].tap do |conf_secrets|
  conf_secrets['database']['connection'] =
    db_uri('container', db_user, db_pass)
  conf_secrets['keystone_auth']['password'] =
    get_password 'service', 'openstack-container'
  conf_secrets['keystone_authtoken']['password'] =
    get_password 'service', 'openstack-container'
end

identity_endpoint = internal_endpoint 'identity'
auth_url = auth_uri_transform identity_endpoint.to_s, node['openstack']['api']['auth']['version']

node.default['openstack']['container']['conf'].tap do |conf|
  conf['api']['host'] = bind_service_address
  conf['api']['port'] = bind_service['port']
  conf['keystone_authtoken']['auth_url'] = auth_url
  conf['service_credentials']['auth_url'] = auth_url
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

python_execute 'zun deps' do
  virtualenv node['openstack']['container']['virtualenv']
  command '-m pip install -I -r requirements.txt'
  cwd ::File.join(zun_dir)
  action :nothing
end

python_execute 'zun install' do
  virtualenv node['openstack']['container']['virtualenv']
  command 'setup.py install'
  cwd ::File.join(zun_dir)
  action :nothing
end

git zun_dir do
  revision node['openstack']['container']['release']
  repository node['openstack']['container']['repository']
  notifies :run, 'python_execute[zun deps]', :immediately
  notifies :run, 'python_execute[zun install]', :immediately
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
end
