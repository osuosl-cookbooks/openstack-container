#
# Cookbook:: openstack-container
# Recipe:: api
#
# Copyright:: 2019-2020, Oregon State University
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
  include Apache2::Cookbook::Helpers
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

# Finds and appends the listen port to the apache2_install[openstack]
# resource which is defined in openstack-identity::server-apache.
apache_resource = find_resource(:apache2_install, 'openstack')

if apache_resource
  apache_resource.listen = [apache_resource.listen, "#{bind_service['host']}:#{bind_service['port']}"].flatten
  edit_resource(:service, 'apache2') do
    subscribes :restart, 'template[/etc/zun/zun.conf]'
  end
else
  apache2_install 'openstack' do
    listen "#{bind_service_address}:#{bind_service['port']}"
    subscribes :restart, 'template[/etc/zun/zun.conf]'
  end
end

apache2_module 'wsgi'
apache2_module 'ssl' if node['openstack']['container']['ssl']['enabled']

# create the zun-api apache directory
directory "#{default_docroot_dir}/zun" do
  owner 'root'
  group 'root'
  mode '755'
end

# Note: Using lazy here as the wsgi file is not available until after
# the zun-api package is installed during execution phase.
file "#{default_docroot_dir}/zun/app" do
  content lazy { IO.read(node['openstack']['container']['zun-api_wsgi_file']) }
  owner 'root'
  group 'root'
  mode '755'
end

template "#{apache_dir}/sites-available/zun-api.conf" do
  extend Apache2::Cookbook::Helpers
  source 'wsgi-template.conf.erb'
  variables(
    daemon_process: 'zun-api',
    server_host: bind_service_address,
    server_port: bind_service['port'],
    server_entry: "#{default_docroot_dir}/zun/app",
    run_dir: lock_dir,
    log_dir: default_log_dir,
    log_debug: node['openstack']['container']['debug'],
    user: node['openstack']['container']['user'],
    group: node['openstack']['container']['group'],
    use_ssl: node['openstack']['container']['ssl']['enabled'],
    cert_file: node['openstack']['container']['ssl']['certfile'],
    chain_file: node['openstack']['container']['ssl']['chainfile'],
    key_file: node['openstack']['container']['ssl']['keyfile'],
    ca_certs_path: node['openstack']['container']['ssl']['ca_certs_path'],
    cert_required: node['openstack']['container']['ssl']['cert_required'],
    protocol: node['openstack']['container']['ssl']['protocol'],
    ciphers: node['openstack']['container']['ssl']['ciphers'],
    venv: node['openstack']['container']['virtualenv']
  )
  notifies :restart, 'service[apache2]'
end

apache2_site 'zun-api' do
  notifies :restart, 'service[apache2]', :immediately
end
