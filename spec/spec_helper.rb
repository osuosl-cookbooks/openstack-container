require 'chefspec'
require 'chefspec/berkshelf'

CENTOS_7 = {
  platform: 'centos',
  version: '7',
  file_cache_path: '/var/chef/cache',
}.freeze

ALL_PLATFORMS = [
  CENTOS_7,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

shared_context 'identity_stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return('rabbit_servers_value')
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers)
      .and_return([])
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', anything)
      .and_return('keystone_db_pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', anything)
      .and_return('')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'openstack')
      .and_return('openstack')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'user1')
      .and_return('secret1')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('keystone', 'fernet_key0')
      .and_return('thisisfernetkey0')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('keystone', 'fernet_key1')
      .and_return('thisisfernetkey1')
    stub_command("[ ! -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-release ] && [ $(/sbin/sestatus | \
grep -c '^Current mode:.*enforcing') -eq 1 ]").and_return(true)
    stub_command('/usr/sbin/httpd -t')
    allow_any_instance_of(Chef::Recipe).to receive(:search_for)
      .with('os-identity').and_return(
        [{
          'openstack' => {
            'identity' => {
              'admin_tenant_name' => 'admin',
              'admin_user' => 'admin',
            },
          },
        }]
      )
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('identity')
      .and_return('rabbit://openstack:openstack@controller.example.org:5672')
    stub_command("/opt/chef/embedded/bin/gem list -i -v '>= 0.2.0' fog-openstack")
  end
end

shared_context 'container_stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:address_for)
      .with('lo')
      .and_return('127.0.1.1')
    allow_any_instance_of(Chef::Recipe).to receive(:config_by_role)
      .with('rabbitmq-server', 'queue')
      .and_return(
        'host' => 'rabbit-host', 'port' => 'rabbit-port'
      )
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_servers)
      .and_return '1.1.1.1:5672,2.2.2.2:5672'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_identity_bootstrap_token')
      .and_return('bootstrap-token')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('token', 'openstack_vmware_secret_name')
      .and_return 'vmware_secret_name'
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'zun')
      .and_return('db-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-container')
      .and_return('zun-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('service', 'openstack-container-network')
      .and_return('kuryr-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'openstack')
      .and_return('mq-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('user', 'admin')
      .and_return('admin-pass')
    allow_any_instance_of(Chef::Recipe).to receive(:rabbit_transport_url)
      .with('container')
      .and_return('rabbit://openstack:openstack@controller.example.org:5672')
    stub_command("/opt/osc-zun/bin/pip show websockify | grep -q 'Version: 0.8.0'").and_return(false)
  end
end

shared_context 'dashboard_stubs' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:memcached_servers)
      .and_return ['hostA:port', 'hostB:port']
    allow_any_instance_of(Chef::Recipe).to receive(:get_password)
      .with('db', 'horizon')
      .and_return('test-passes')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('certs', 'horizon.pem')
      .and_return('horizon_pem_value')
    allow_any_instance_of(Chef::Recipe).to receive(:secret)
      .with('certs', 'horizon.key')
      .and_return('horizon_key_value')
    stub_command('/usr/sbin/httpd -t')
    stub_command('[ ! -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-rel' \
      "ease ] && [ $(/sbin/sestatus | grep -c '^Current mode:.*enforcing') -e" \
      'q 1 ]').and_return(true)
    stub_command('[ -e /etc/httpd/conf/httpd.conf ] && [ -e /etc/redhat-relea' \
      "se ] && [ $(/sbin/sestatus | grep -c '^Current mode:.*permissive') -eq" \
      "1 ] && [ $(/sbin/sestatus | grep -c '^Mode from config file:.*enforcin" \
      "g') -eq 1 ]").and_return(true)
  end
end
