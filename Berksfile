source 'https://supermarket.chef.io'

solver :ruby, :required

cookbook 'container_test', path: 'test/cookbooks/container_test'
cookbook 'openstackclient', github: 'osuosl-cookbooks/cookbook-openstackclient', branch: 'stein-updates'
cookbook 'openstack-common', github: 'osuosl-cookbooks/cookbook-openstack-common', branch: 'stein-zun'
cookbook 'memcached'

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
           github: "osuosl-cookbooks/cookbook-openstack-#{cb}",
           branch: 'stein-updates'
end

metadata
