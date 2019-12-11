default['openstack']['container-network']['conf_secrets'] = {}
default['openstack']['container-network']['conf'].tap do |conf|
  conf['DEFAULT']['bindir'] = "#{default['openstack']['container-network']['virtualenv']}/libexec/kuryr"
  conf['neutron']['auth_type'] = 'password'
  conf['neutron']['project_domain_name'] = 'default'
  conf['neutron']['project_name'] = 'service'
  conf['neutron']['user_domain_name'] = 'default'
  conf['neutron']['username'] = 'kuryr'
end
