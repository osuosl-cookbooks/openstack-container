# # encoding: utf-8

# Inspec test for recipe openstack-container::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe group 'zun' do
  it { should exist }
  its('gid') { should < 1000 }
end

describe user 'zun' do
  it { should exist }
  its('uid') { should < 1000 }
  its('group') { should eq 'zun' }
  its('home') { should eq '/var/lib/zun' }
  its('shell') { should eq '/bin/false' }
end

describe command 'zun --version' do
  its('exit_status') { should eq 0 }
  its('stderr') { should match '3.3.0' }
end

%w(/etc/zun /var/lib/zun/tmp).each do |d|
  describe directory d do
    its('owner') { should eq 'zun' }
    its('group') { should eq 'zun' }
    its('mode') { should cmp '0750' }
  end
end

describe file '/etc/zun/zun.conf' do
  its('owner') { should eq 'zun' }
  its('group') { should eq 'zun' }
  its('mode') { should cmp '0640' }
end

describe ini '/etc/zun/zun.conf' do
  its('DEFAULT.image_driver_list') { should eq 'docker' }
  its('DEFAULT.transport_url') { should eq 'rabbit://openstack:openstack@127.0.0.1:5672/' }
  its('keystone_authtoken.auth_type') { should eq 'v3password' }
  its('keystone_authtoken.project_domain_name') { should eq 'Default' }
  its('keystone_authtoken.project_name') { should eq 'service' }
  its('keystone_authtoken.region_name') { should eq 'RegionOne' }
  its('keystone_authtoken.service_token_roles_required') { should eq 'true' }
  its('keystone_authtoken.user_domain_name') { should eq 'Default' }
  its('keystone_authtoken.username') { should eq 'zun' }
  its('keystone_authtoken.auth_url') { should eq 'http://127.0.0.1:5000/v3' }
  its('keystone_authtoken.www_authenticate_uri') { should eq 'http://127.0.0.1:5000/v3' }
  its('keystone_authtoken.password') { should eq 'openstack-container' }
  its('keystone_auth.auth_type') { should eq 'v3password' }
  its('keystone_auth.project_domain_name') { should eq 'Default' }
  its('keystone_auth.project_name') { should eq 'service' }
  its('keystone_auth.region_name') { should eq 'RegionOne' }
  its('keystone_auth.user_domain_name') { should eq 'Default' }
  its('keystone_auth.username') { should eq 'zun' }
  its('keystone_auth.auth_url') { should eq 'http://127.0.0.1:5000/v3' }
  its('keystone_auth.www_authenticate_uri') { should eq 'http://127.0.0.1:5000/v3' }
  its('keystone_auth.password') { should eq 'openstack-container' }
  its('oslo_concurrency.lock_path') { should eq '/var/lib/zun/tmp' }
  its('api.host') { should eq '127.0.0.1' }
  its('api.port') { should eq '9517' }
  its('docker.docker_remote_api_host') { should eq '127.0.0.1' }
  its('docker.docker_remote_api_port') { should eq '2375' }
  its('etcd.etcd_host') { should eq '127.0.0.1' }
  its('etcd.etcd_port') { should eq '2379' }
  its('database.connection') { should eq 'mysql+pymysql://zun:zun@127.0.0.1:3306/zun?charset=utf8' }
end

describe command '/opt/osc-zun/bin/pip show websockify' do
  its('stdout') { should match /Version: 0.8.0/ }
end
