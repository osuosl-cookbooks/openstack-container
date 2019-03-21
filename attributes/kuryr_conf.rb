default['openstack']['container-network']['conf_secrets'] = {}
default['openstack']['container-network']['conf'].tap do |conf|
  # conf['DEFAULT']['debug'] = true
  # conf['DEFAULT']['verbose'] = true
  conf['DEFAULT']['bindir'] = "#{default['openstack']['container-network']['virtualenv']}/libexec/kuryr"
  conf['neutron']['username'] = 'kuryr'
  conf['neutron']['user_domain_name'] = 'default'
  conf['neutron']['project_name'] = 'service'
  conf['neutron']['project_domain_name'] = 'default'
  conf['neutron']['auth_type'] = 'password'
end
