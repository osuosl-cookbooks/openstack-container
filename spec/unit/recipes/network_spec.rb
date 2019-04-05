require_relative '../../spec_helper'

describe 'openstack-container::network' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'container_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(build-essential git).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end
      it do
        expect(chef_run).to install_python_runtime('osc-kuryr')
          .with(
            version: '2',
            provider: PoisePython::PythonProviders::System,
            pip_version: '9.0.3'
          )
      end
      it do
        expect(chef_run).to create_python_virtualenv('/opt/osc-kuryr')
          .with(
            python: '/usr/bin/python',
            system_site_packages: true
          )
      end
      it do
        expect(chef_run).to install_python_package('setuptools')
          .with(
            # virtualenv: '/opt/osc-kuryr',
            version: '40.8.0'
          )
      end
      it do
        expect(chef_run).to create_group('kuryr').with(system: true)
      end
      it do
        expect(chef_run).to create_user('kuryr')
          .with(
            home: '/var/lib/kuryr',
            manage_home: true,
            system: true,
            shell: '/bin/false',
            gid: 'kuryr'
          )
      end
      it do
        expect(chef_run).to nothing_python_execute('kuryr deps')
          .with(
            # virtualenv: '/opt/osc-kuryr',
            command: '-m pip install -I -r requirements.txt',
            cwd: '/var/chef/cache/kuryr-libnetwork'
          )
      end
      it do
        expect(chef_run).to nothing_python_execute('kuryr install')
          .with(
            # virtualenv: '/opt/osc-kuryr',
            command: 'setup.py install',
            cwd: '/var/chef/cache/kuryr-libnetwork'
          )
      end
      it do
        expect(chef_run).to sync_git('/var/chef/cache/kuryr-libnetwork')
          .with(
            revision: '1.0.0',
            repository: 'https://git.openstack.org/openstack/kuryr-libnetwork.git'
          )
      end
      it do
        expect(chef_run.git('/var/chef/cache/kuryr-libnetwork')).to notify('python_execute[kuryr deps]')
          .to(:run).immediately
      end
      it do
        expect(chef_run.git('/var/chef/cache/kuryr-libnetwork')).to notify('python_package[setuptools]')
          .to(:install).immediately
      end
      it do
        expect(chef_run.git('/var/chef/cache/kuryr-libnetwork')).to notify('python_execute[kuryr install]')
          .to(:run).immediately
      end
      %w(/etc/kuryr /var/lib/kuryr).each do |d|
        it do
          expect(chef_run).to create_directory(d)
            .with(
              user: 'kuryr',
              group: 'kuryr'
            )
        end
      end
      it do
        expect(chef_run).to create_template('/etc/kuryr/kuryr.conf')
          .with(
            source: 'openstack-service.conf.erb',
            cookbook: 'openstack-common',
            owner: 'kuryr',
            group: 'kuryr',
            variables: {
              service_config: {
                'DEFAULT' => {
                  'bindir' => '/opt/osc-kuryr/libexec/kuryr',
                },
                'neutron' => {
                  'auth_type' => 'password',
                  'project_domain_name' => 'default',
                  'project_name' => 'service',
                  'user_domain_name' => 'default',
                  'username' => 'kuryr',
                  'auth_url' => 'http://127.0.0.1:5000/v3',
                  'www_authenticate_uri' => 'http://127.0.0.1:5000/v3',
                  'password' => 'kuryr-pass',
                },
              },
            }
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/usr/lib/docker/plugins/kuryr/kuryr.json')
      end
      it do
        expect(chef_run).to create_systemd_unit('kuryr-libnetwork.service')
          .with(
            content: {
              'Install' => { 'WantedBy' => 'multi-user.target' },
              'Service' => {
                'ExecStart' => '/opt/osc-kuryr/bin/kuryr-server --config-file /etc/kuryr/kuryr.conf',
                'CapabilityBoundingSet' => 'CAP_NET_ADMIN',
              },
              'Unit' => { 'Description' => 'Kuryr-libnetwork - Docker network plugin for Neutron' },
            }
          )
      end
    end
  end
end
