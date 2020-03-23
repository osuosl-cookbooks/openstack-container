execute 'create-fake-eth1' do
  command <<-EOF
    modprobe dummy
    ip link set name eth1 dev dummy0
  EOF
  not_if 'ip a show dev eth1'
end

node.default['openstack']['bind_service']['all']['container']['host'] = node['ipaddress']
node.default['openstack']['bind_service']['all']['container-wsproxy']['host'] = node['ipaddress']
node.default['openstack']['bind_service']['all']['container-network']['host'] = node['ipaddress']
node.default['openstack']['bind_service']['all']['container-docker']['host'] = node['ipaddress']
node.default['openstack']['bind_service']['all']['container-etcd']['host'] = node['ipaddress']
node.default['openstack']['endpoints']['public']['container']['host'] = node['ipaddress']
node.default['openstack']['endpoints']['internal']['container']['host'] = node['ipaddress']
node.default['openstack']['endpoints']['admin']['container']['host'] = node['ipaddress']
node.default['openstack']['endpoints']['public']['container-network']['host'] = node['ipaddress']
node.default['openstack']['endpoints']['internal']['container-network']['host'] = node['ipaddress']
node.default['openstack']['endpoints']['admin']['container-network']['host'] = node['ipaddress']
