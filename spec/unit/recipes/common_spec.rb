require_relative '../../spec_helper'

describe 'openstack-container::common' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'identity_stubs'
      include_context 'container_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(openstack-common git).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end
      it do
        expect(chef_run).to install_build_essential('openstack-container-common')
      end
      it do
        expect(chef_run).to run_execute('virtualenv /opt/osc-zun').with(creates: '/opt/osc-zun')
      end
      it do
        expect(chef_run).to run_execute('/opt/osc-zun/bin/pip install PyMySQL')
          .with(creates: '/opt/osc-zun/lib/python2.7/site-packages/pymysql')
      end
      zunclient_pkgs =
        %w(
          python2-docker
          python2-keystoneauth1
          python2-openstackclient
          python2-osc-lib
          python2-oslo-i18n
          python2-oslo-log
          python2-oslo-utils
          python2-pbr
          python2-pyyaml
          python-prettytable
          python-websocket-client
        )
      it do
        expect(chef_run).to install_package(zunclient_pkgs)
      end
      it do
        expect(chef_run).to run_execute('install python-zunclient').with(
          command: '/usr/bin/pip install python-zunclient==3.3.0',
          creates: '/usr/lib/python2.7/site-packages/zunclient'
        )
      end
      it do
        expect(chef_run).to install_package(%w(libffi-devel openssl-devel pciutils))
      end
      it do
        expect(chef_run).to upgrade_package('MySQL-python')
      end
      it do
        expect(chef_run).to create_group('zun').with(system: true)
      end
      it do
        expect(chef_run).to create_user('zun')
          .with(
            home: '/var/lib/zun',
            manage_home: true,
            system: true,
            shell: '/bin/false',
            gid: 'zun'
          )
      end
      it do
        expect(chef_run).to nothing_execute('zun deps')
          .with(
            command: '/opt/osc-zun/bin/pip install -I -r requirements.txt python_memcached',
            cwd: '/var/chef/cache/zun'
          )
      end
      it do
        expect(chef_run).to nothing_execute('zun install')
          .with(
            command: '/opt/osc-zun/bin/python setup.py install',
            cwd: '/var/chef/cache/zun'
          )
      end
      it do
        expect(chef_run).to sync_git('/var/chef/cache/zun')
          .with(
            revision: 'stable/stein',
            repository: 'https://opendev.org/openstack/zun.git'
          )
      end
      it do
        expect(chef_run.git('/var/chef/cache/zun')).to notify('execute[zun deps]').to(:run).immediately
      end
      it do
        expect(chef_run.git('/var/chef/cache/zun')).to notify('execute[zun install]').to(:run).immediately
      end
      it do
        expect(chef_run).to run_execute('install websockify').with(
          command: "/opt/osc-zun/bin/pip install \'websockify<0.9.0\'"
        )
      end
      context 'websockify already installed' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p).converge(described_recipe)
        end
        before do
          stub_command("/opt/osc-zun/bin/pip show websockify | grep -q 'Version: 0.8.0'").and_return(true)
        end
        it do
          expect(chef_run).to_not run_execute('install websockify')
        end
      end
      %w(/etc/zun /var/lib/zun/tmp).each do |d|
        it do
          expect(chef_run).to create_directory(d)
            .with(
              user: 'zun',
              group: 'zun',
              mode: '0750'
            )
        end
      end
      it do
        expect(chef_run).to create_template('/etc/zun/zun.conf')
          .with(
            source: 'openstack-service.conf.erb',
            cookbook: 'openstack-common',
            owner: 'zun',
            group: 'zun',
            mode: '0640',
            variables: {
              service_config: {
                'DEFAULT' => {
                  'image_driver_list' => 'docker',
                  'state_path' => '/var/lib/zun',
                  'transport_url' => 'rabbit://openstack:openstack@controller.example.org:5672',
                },
                'keystone_authtoken' => {
                  'auth_type' => 'v3password',
                  'project_domain_name' => 'Default',
                  'project_name' => 'service',
                  'region_name' => 'RegionOne',
                  'service_token_roles_required' => true,
                  'user_domain_name' => 'Default',
                  'username' => 'zun',
                  'auth_url' => 'http://127.0.0.1:5000/v3',
                  'www_authenticate_uri' => 'http://127.0.0.1:5000/v3',
                  'password' => 'zun-pass',
                },
                'keystone_auth' => {
                  'auth_type' => 'v3password',
                  'project_domain_name' => 'Default',
                  'project_name' => 'service',
                  'region_name' => 'RegionOne',
                  'user_domain_name' => 'Default',
                  'username' => 'zun',
                  'auth_url' => 'http://127.0.0.1:5000/v3',
                  'www_authenticate_uri' => 'http://127.0.0.1:5000/v3',
                  'password' => 'zun-pass',
                },
                'oslo_concurrency' => {
                  'lock_path' => '/var/lib/zun/tmp',
                },
                'api' => {
                  'host' => '127.0.0.1',
                  'port' => 9517,
                },
                'docker' => {
                  'docker_remote_api_host' => '127.0.0.1',
                  'docker_remote_api_port' => '2375',
                },
                'etcd' => {
                  'etcd_host' => '127.0.0.1',
                  'etcd_port' => '2379',
                },
                'database' => {
                  'connection' => 'mysql+pymysql://zun:db-pass@127.0.0.1:3306/zun?charset=utf8',
                },
              },
            }
          )
      end
    end
  end
end
