source 'https://supermarket.chef.io'

solver :ruby, :required

cookbook 'container_test', path: 'test/cookbooks/container_test'
cookbook 'openstackclient', github: 'openstack/cookbook-openstackclient'
cookbook 'openstack-common', github: 'osuosl-cookbooks/cookbook-openstack-common', branch: 'master-zun'

# Openstack deps
%w(
  dashboard
  identity
  image
  network
  ops-database
  ops-messaging
).each do |cb|
  cookbook "openstack-#{cb}",
           github: "openstack/cookbook-openstack-#{cb}",
           branch: 'master'
end

metadata
