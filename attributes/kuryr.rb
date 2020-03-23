default['openstack']['container-network']['user'] = 'kuryr'
default['openstack']['container-network']['group'] = 'kuryr'
default['openstack']['container-network']['virtualenv'] = '/opt/osc-kuryr'
default['openstack']['container-network']['release'] = 'stable/stein'
default['openstack']['container-network']['repository'] = 'https://opendev.org/openstack/kuryr-libnetwork.git'
default['openstack']['bind_service']['all']['container-network']['port'] = 9517
default['openstack']['bind_service']['all']['container-network']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['container-wsproxy']['port'] = 6784
default['openstack']['bind_service']['all']['container-wsproxy']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['container-docker']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['container-docker']['port'] = '2375'
default['openstack']['bind_service']['all']['container-etcd']['host'] = '127.0.0.1'
default['openstack']['bind_service']['all']['container-etcd']['port'] = '2379'
%w(public internal admin).each do |ep_type|
  default['openstack']['endpoints'][ep_type]['container-network']['host'] = '127.0.0.1'
  default['openstack']['endpoints'][ep_type]['container-network']['scheme'] = 'http'
  default['openstack']['endpoints'][ep_type]['container-network']['path'] = '/v1'
  default['openstack']['endpoints'][ep_type]['container-network']['port'] = 9517
end
default['openstack']['container-network']['custom_template_banner'] = '
# This file is automatically generated by Chef
# Any changes will be overwritten
'
default['openstack']['container-network']['conf_dir'] = '/etc/kuryr'
default['openstack']['container-network']['conf_file'] = ::File.join(node['openstack']['container-network']['conf_dir'], 'kuryr.conf')
default['openstack']['container-network']['service_role'] = 'admin'
default['openstack']['container-network']['misc_paste'] = nil
default['openstack']['container-network']['kuryr_service'] = 'httpd'
default['openstack']['container']['network']['unit'] = {
  'Unit' => {
    'Description' => 'Kuryr-libnetwork - Docker network plugin for Neutron',
  },
  'Service' => {
    'ExecStart' => "#{node['openstack']['container-network']['virtualenv']}/bin/kuryr-server --config-file /etc/kuryr/kuryr.conf",
    'CapabilityBoundingSet' => 'CAP_NET_ADMIN',
  },
  'Install' => {
    'WantedBy' => 'multi-user.target',
  },
}
