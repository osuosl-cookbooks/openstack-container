#
# Cookbook:: openstack-container
# Recipe:: api
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

zun_user = node['openstack']['container']['user']
zun_group = node['openstack']['container']['group']
bind_service = node['openstack']['bind_service']['all']['container']
bind_service_address = bind_address bind_service

node.default['openstack']['container']['conf'].tap do |conf|
  conf['oslo_messaging_notifications']['driver'] = 'messaging'
end

include_recipe 'openstack-common::etcd'
include_recipe 'openstack-container::common'

template '/etc/zun/api-paste.ini' do
  source 'api-paste.ini.erb'
  owner zun_user
  group zun_group
  mode '0644'
end

cookbook_file '/etc/zun/policy.json' do
  owner 'root'
  group zun_group
  mode '0640'
end

execute 'zun-db-manage upgrade' do
  command '/opt/osc-zun/bin/zun-db-manage upgrade'
  user zun_user
  group zun_group
end

# configure attributes for apache2 cookbook to align with openstack settings
apache_listen = Array(node['apache']['listen']) # include already defined listen attributes
# Remove the default apache2 cookbook port, as that is also the default for horizon, but with
# a different address syntax.  *:80   vs  0.0.0.0:80
apache_listen -= ['*:80']
apache_listen += ["#{bind_service_address}:#{bind_service['port']}"]
node.normal['apache']['listen'] = apache_listen.uniq

# include the apache2 default recipe and the recipes for mod_wsgi
include_recipe 'apache2'
include_recipe 'apache2::mod_wsgi'
# include the apache2 mod_ssl recipe if ssl is enabled for identity
include_recipe 'apache2::mod_ssl' if node['openstack']['identity']['ssl']['enabled']

# create the zun-api apache directory
zun_apache_dir = "#{node['apache']['docroot_dir']}/zun"

directory zun_apache_dir do
  owner 'root'
  group 'root'
  mode 0o0755
end

zun_server_entry = "#{zun_apache_dir}/app"
# Note: Using lazy here as the wsgi file is not available until after
# the zun-api package is installed during execution phase.
file zun_server_entry do
  content lazy { IO.read(node['openstack']['container']['zun-api_wsgi_file']) }
  owner 'root'
  group 'root'
  mode 0o0755
end

web_app 'zun-api' do
  template 'wsgi-template.conf.erb'
  daemon_process 'zun-api'
  server_host bind_service['host']
  server_port bind_service['port']
  server_entry zun_server_entry
  run_dir node['apache']['run_dir']
  log_dir node['apache']['log_dir']
  log_debug node['openstack']['container']['debug']
  user node['openstack']['container']['user']
  group node['openstack']['container']['group']
  use_ssl node['openstack']['container']['ssl']['enabled']
  cert_file node['openstack']['container']['ssl']['certfile']
  chain_file node['openstack']['container']['ssl']['chainfile']
  key_file node['openstack']['container']['ssl']['keyfile']
  ca_certs_path node['openstack']['container']['ssl']['ca_certs_path']
  cert_required node['openstack']['container']['ssl']['cert_required']
  protocol node['openstack']['container']['ssl']['protocol']
  ciphers node['openstack']['container']['ssl']['ciphers']
  venv node['openstack']['container']['virtualenv']
  notifies :reload, 'service[zun-api]'
end

service 'zun-api' do
  service_name node['openstack']['container']['zun_service']
  subscribes :restart, "template[#{node['openstack']['container']['conf_file']}]"
  action [:enable, :start]
end
