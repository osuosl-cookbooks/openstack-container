# # encoding: utf-8

# Inspec test for recipe openstack-container::identity_registration

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe command('bash -c "source /root/openrc && openstack service list -f value -c Name -c Type"') do
  its('stdout') { should match /^zun container$/ }
end

describe command('bash -c "source /root/openrc && openstack endpoint list --service zun -f value"') do
  its('stdout') { should match %r{RegionOne zun container True public http://127.0.0.1:9517/v1$} }
  its('stdout') { should match %r{RegionOne zun container True internal http://127.0.0.1:9517/v1$} }
end

describe command('bash -c "source /root/openrc && openstack user list -c Name -f value"') do
  its('stdout') { should match /^zun$/ }
  its('stdout') { should match /^kuryr$/ }
end
