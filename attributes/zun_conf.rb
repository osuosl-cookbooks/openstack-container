default['openstack']['container']['conf_secrets'] = {}
default['openstack']['container']['conf'].tap do |conf|
  # conf['DEFAULT']['debug'] = true
  # conf['DEFAULT']['verbose'] = true
  conf['DEFAULT']['image_driver_list'] = 'docker'
  # [keystone_authtoken] section
  conf['keystone_authtoken']['username'] = 'zun'
  conf['keystone_authtoken']['project_name'] = 'service'
  conf['keystone_authtoken']['auth_type'] = 'v3password'
  conf['keystone_authtoken']['user_domain_name'] = 'Default'
  conf['keystone_authtoken']['project_domain_name'] = 'Default'
  conf['keystone_authtoken']['region_name'] = node['openstack']['region']
  conf['keystone_authtoken']['service_token_roles_required'] = true
  # [keystone_auth] section
  conf['keystone_auth']['username'] = 'zun'
  conf['keystone_auth']['project_name'] = 'service'
  conf['keystone_auth']['auth_type'] = 'v3password'
  conf['keystone_auth']['user_domain_name'] = 'Default'
  conf['keystone_auth']['project_domain_name'] = 'Default'
  conf['keystone_auth']['region_name'] = node['openstack']['region']
  conf['oslo_concurrency']['lock_path'] = '/var/lib/zun/tmp'
end
