#
# Cookbook:: openstack-container
# Recipe:: wsproxy
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
end

bind_service = node['openstack']['bind_service']['all']['container-wsproxy']
bind_service_address = bind_address bind_service

node.default['openstack']['container']['conf'].tap do |conf|
  conf['websocket_proxy']['wsproxy_host'] = bind_service_address
  conf['websocket_proxy']['wsproxy_port'] = bind_service['port']
  conf['websocket_proxy']['base_url'] = "ws://#{bind_service_address}:#{bind_service['port']}/"
end

include_recipe 'openstack-container::common'

systemd_unit 'zun-wsproxy.service' do
  content node['openstack']['container']['wsproxy']['unit']
  action [:create]
end

service 'zun-wsproxy' do
  action [:enable, :start]
  subscribes :restart, "template[#{node['openstack']['container']['conf_file']}]"
  subscribes :restart, 'systemd_unit[zun-wsproxy.service]'
  subscribes :restart, 'execute[install websockify]'
end
