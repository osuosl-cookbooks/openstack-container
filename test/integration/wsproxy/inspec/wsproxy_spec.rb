# # encoding: utf-8

# Inspec test for recipe openstack-container::wsproxy

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe ini '/etc/systemd/system/zun-wsproxy.service' do
  its('Unit.Description') { should cmp 'OpenStack Container Service Websocket Proxy' }
  its('Service.ExecStart') { should cmp '/opt/osc-zun/bin/zun-wsproxy' }
  its('Service.User') { should cmp 'zun' }
  its('Install.WantedBy') { should cmp 'multi-user.target' }
end

describe service 'zun-wsproxy' do
  it { should be_enabled }
  it { should be_running }
end

describe port(6784) do
  it { should be_listening }
  its('processes') { should include 'zun-wsproxy' }
end
