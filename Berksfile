source 'https://supermarket.chef.io'

solver :ruby, :required

cookbook 'openstack-common', github: 'osuosl-cookbooks/cookbook-openstack-common', branch: 'master-zun'
cookbook 'container_test', path: 'test/cookbooks/container_test'

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
