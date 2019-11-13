require_relative '../../spec_helper'

describe 'openstack-container::compute' do
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
      %w(openstack-container::common sudo).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end
      it do
        expect(chef_run).to create_cookbook_file('/etc/zun/rootwrap.conf')
          .with(
            group: 'zun',
            mode: '0640'
          )
      end
      it do
        expect(chef_run).to create_directory('/etc/zun/rootwrap.d')
          .with(
            user: 'zun',
            group: 'zun',
            mode: '0750'
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/etc/zun/rootwrap.d/zun.filters')
          .with(
            group: 'zun',
            mode: '0640'
          )
      end
      it do
        expect(chef_run).to create_sudo('zun')
          .with(
            commands: ['/opt/osc-zun/bin/zun-rootwrap /etc/zun/rootwrap.conf *'],
            users: %w(zun),
            nopasswd: true,
            defaults: [
              'secure_path=/opt/osc-zun/bin:/sbin:/bin:/usr/sbin:/usr/bin',
              '!requiretty',
            ]
          )
      end
      it do
        expect(chef_run).to create_docker_service('zun')
          .with(
            host: [
              'tcp://127.0.0.1:2375',
              'unix:///var/run/docker.sock',
            ],
            cluster_store: 'etcd://127.0.0.1:2379',
            group: 'zun'
          )
      end
      it do
        expect(chef_run).to start_docker_service('zun')
      end
      it do
        expect(chef_run).to create_systemd_unit('zun-compute.service')
          .with(
            content: {
              'Install' => {
                'WantedBy' => 'multi-user.target',
              },
              'Service' => {
                'Environment' => 'PATH=/opt/osc-zun/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
                'ExecStart' => '/opt/osc-zun/bin/zun-compute',
                'User' => 'zun',
              },
              'Unit' => {
                'Description' => 'OpenStack Container Service Compute Agent',
              },
            }
          )
      end
      it do
        expect(chef_run).to enable_service('zun-compute')
      end
      it do
        expect(chef_run).to start_service('zun-compute')
      end
      it do
        expect(chef_run.service('zun-compute')).to subscribe_to('template[/etc/zun/zun.conf]').on(:restart)
      end
    end
  end
end
