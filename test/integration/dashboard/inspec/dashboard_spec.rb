# # encoding: utf-8

# Inspec test for recipe openstack-container::dashboard

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe pip 'zun-ui' do
  it { should be_installed }
  its('version') { should <= '3.0.1' }
end

%w(
  _1330_project_container_panelgroup.py
  _1331_project_container_containers_panel.py
  _2330_admin_container_panelgroup.py
  _2331_admin_container_images_panel.py
).each do |f|
  describe file ::File.join('/usr/share/openstack-dashboard/openstack_dashboard/local/enabled', f) do
    it { should exist }
  end
end
