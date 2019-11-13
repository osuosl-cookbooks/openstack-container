# # encoding: utf-8

# Inspec test for recipe openstack-container::api

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe file '/etc/zun/api-paste.ini' do
  its('mode') { should cmp '0644' }
  its('owner') { should eq 'zun' }
  its('group') { should eq 'zun' }
end

describe file '/etc/zun/policy.json' do
  its('mode') { should cmp '0640' }
  its('owner') { should eq 'root' }
  its('group') { should eq 'zun' }
end

describe directory '/var/www/html/zun' do
  its('mode') { should cmp '0755' }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
end

describe file '/var/www/html/zun/app' do
  its('mode') { should cmp '0755' }
  its('owner') { should eq 'root' }
  its('group') { should eq 'root' }
  its('content') { should match /from zun.api import wsgi/ }
end

describe apache_conf '/etc/httpd/sites-enabled/zun-api.conf' do
  its('WSGIDaemonProcess') { should cmp 'zun-api processes=2 threads=10 user=zun group=zun display-name=%{GROUP} python-home=/opt/osc-zun' }
  its('WSGIProcessGroup') { should include 'zun-api' }
  its('WSGIScriptAlias') { should cmp '/ /var/www/html/zun/app' }
  its('ErrorLog') { should cmp '/var/log/httpd/zun-api_error.log' }
  its('CustomLog') { should cmp '/var/log/httpd/zun-api_access.log combined' }
  its('WSGISocketPrefix') { should cmp '/var/run/httpd' }
end

describe file '/etc/httpd/sites-enabled/zun-api.conf' do
  its('content') { should match /VirtualHost 127.0.0.1:9517/ }
  its('content') { should match %r{Directory /var/www/html/zun} }
end

describe port(9517) do
  it { should be_listening }
  its('processes') { should include 'httpd' }
end

describe command('bash -c "source /root/openrc && openstack appcontainer list"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should eq "\n" }
end

describe file '/var/log/httpd/zun-api_error.log' do
  its('content') { should_not match /ERROR/ }
end
