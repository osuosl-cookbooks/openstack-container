#
# Cookbook:: openstack-container
# Recipe:: compute
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

include_recipe 'openstack-container::common'

zun_user = node['openstack']['container']['user']
zun_group = node['openstack']['container']['group']
bind_service = node['openstack']['bind_service']['all']['container']
bind_service_address = bind_address bind_service
bind_docker = node['openstack']['bind_service']['all']['container-docker']
bind_docker_address = bind_address bind_docker

cookbook_file '/etc/zun/rootwrap.conf' do
  group zun_group
  mode '0640'
end

directory '/etc/zun/rootwrap.d' do
  user zun_user
  group zun_user
  mode '0750'
end

cookbook_file '/etc/zun/rootwrap.d/zun.filters' do
  group zun_group
  mode '0640'
end

file '/etc/sudoers.d/zun-rootwrap' do
  content "#{zun_user} ALL=(root) NOPASSWD: #{node['openstack']['container']['virtualenv']}/bin/zun-rootwrap " \
          "/etc/zun/rootwrap.conf *\n"
  mode '0400'
end

docker_service 'zun' do
  host [
    "tcp://#{bind_docker_address}:#{bind_docker['port']}",
    'unix:///var/run/docker.sock',
  ]
  cluster_store "etcd://#{bind_service_address}:2379"
  group zun_group
  action [:create, :start]
end

systemd_unit 'zun-compute.service' do
  content node['openstack']['container']['compute']['unit']
  action [:create, :enable, :start]
  subscribes :reload_or_try_restart, "template[#{node['openstack']['container']['conf_file']}]"
end
