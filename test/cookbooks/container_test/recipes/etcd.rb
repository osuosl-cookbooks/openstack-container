edit_resource(:etcd_service, 'openstack') do
  advertise_client_urls "http://#{node['ipaddress']}:2379"
  listen_client_urls "http://#{node['ipaddress']}:2379"
end
