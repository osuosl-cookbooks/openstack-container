require_relative '../../spec_helper'

describe 'openstack-container::dashboard' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'identity_stubs'
      include_context 'container_stubs'
      include_context 'dashboard_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(openstack-common openstack-dashboard::horizon).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end
      it do
        expect(chef_run).to nothing_execute('zun-ui install')
          .with(
            command: '/usr/bin/pip install .',
            cwd: '/var/chef/cache/zun-ui'
          )
      end
      it do
        expect(chef_run).to sync_git('/var/chef/cache/zun-ui')
          .with(
            revision: 'stable/rocky',
            repository: 'https://git.openstack.org/openstack/zun-ui.git'
          )
      end
      it do
        expect(chef_run.git('/var/chef/cache/zun-ui')).to \
          notify('execute[zun-ui install]').to(:run).immediately
      end
      dash_dir = '/usr/share/openstack-dashboard/openstack_dashboard/local/enabled'
      %w(
        _1330_project_container_panelgroup.py
        _1331_project_container_containers_panel.py
        _2330_admin_container_panelgroup.py
        _2331_admin_container_images_panel.py
      ).each do |f|
        it do
          expect(chef_run).to create_remote_file("#{dash_dir}/#{f}")
            .with(
              source: "file:///var/chef/cache/zun-ui/zun_ui/enabled/#{f}"
            )
        end
        it do
          expect(chef_run.remote_file("#{dash_dir}/#{f}")).to notify('service[apache2]').to(:restart)
        end
      end
    end
  end
end
