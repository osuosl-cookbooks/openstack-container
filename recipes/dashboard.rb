#
# Cookbook:: openstack-container
# Recipe:: dashboard
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
include_recipe 'openstack-common'
include_recipe 'openstack-dashboard::horizon'

zun_ui_dir = ::File.join(Chef::Config[:file_cache_path], 'zun-ui')

execute 'zun-ui install' do
  command '/usr/bin/pip install .'
  cwd ::File.join(zun_ui_dir)
  action :nothing
end

git zun_ui_dir do
  revision node['openstack']['container-ui']['release']
  repository node['openstack']['container-ui']['repository']
  notifies :run, 'execute[zun-ui install]', :immediately
end

node['openstack']['container-ui']['files'].each do |f|
  remote_file "/usr/share/openstack-dashboard/openstack_dashboard/local/enabled/#{f}" do
    source "file://#{zun_ui_dir}/zun_ui/enabled/#{f}"
    notifies :restart, 'service[apache2]'
  end
end
