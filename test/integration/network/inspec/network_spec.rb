# # encoding: utf-8

# Inspec test for recipe openstack-container::network

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe group 'kuryr' do
  it { should exist }
  its('gid') { should < 1000 }
end

describe user 'kuryr' do
  it { should exist }
  its('uid') { should < 1000 }
  its('group') { should eq 'kuryr' }
  its('home') { should eq '/var/lib/kuryr' }
  its('shell') { should eq '/bin/false' }
end

%w(/etc/kuryr /var/lib/kuryr).each do |d|
  describe directory d do
    its('owner') { should eq 'kuryr' }
    its('group') { should eq 'kuryr' }
  end
end

describe ini '/etc/kuryr/kuryr.conf' do
  its('DEFAULT.bindir') { should cmp '/opt/osc-kuryr/libexec/kuryr' }
  its('neutron.auth_type') { should cmp 'password' }
  its('neutron.project_domain_name') { should cmp 'default' }
  its('neutron.project_name') { should cmp 'service' }
  its('neutron.user_domain_name') { should cmp 'default' }
  its('neutron.username') { should cmp 'kuryr' }
  its('neutron.auth_url') { should cmp 'http://127.0.0.1:5000/v3' }
  its('neutron.www_authenticate_uri') { should cmp 'http://127.0.0.1:5000/v3' }
  its('neutron.password') { should cmp 'openstack-container-network' }
end

describe file '/etc/kuryr/kuryr.conf' do
  its('owner') { should eq 'kuryr' }
  its('group') { should eq 'kuryr' }
end

describe file '/usr/lib/docker/plugins/kuryr/kuryr.json' do
  it { should exist }
end

describe ini '/etc/systemd/system/kuryr-libnetwork.service' do
  its('Unit.Description') { should cmp 'Kuryr-libnetwork - Docker network plugin for Neutron' }
  its('Service.ExecStart') { should cmp '/opt/osc-kuryr/bin/kuryr-server --config-file /etc/kuryr/kuryr.conf' }
  its('Service.CapabilityBoundingSet') { should cmp 'CAP_NET_ADMIN' }
  its('Install.WantedBy') { should cmp 'multi-user.target' }
end

describe service 'kuryr-libnetwork.service' do
  it { should be_enabled }
  it { should be_running }
end

describe port(23750) do
  it { should be_listening }
  its('processes') { should include 'kuryr-server' }
end
