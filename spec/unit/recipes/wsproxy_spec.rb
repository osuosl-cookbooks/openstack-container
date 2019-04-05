require_relative '../../spec_helper'

describe 'openstack-container::wsproxy' do
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
      it do
        expect(chef_run).to include_recipe('openstack-container::common')
      end
      it do
        expect(chef_run).to create_systemd_unit('zun-wsproxy.service')
          .with(
            content: {
              'Install' => { 'WantedBy' => 'multi-user.target' },
              'Service' => {
                'ExecStart' => '/opt/osc-zun/bin/zun-wsproxy',
                'User' => 'zun',
              },
              'Unit' => { 'Description' => 'OpenStack Container Service Websocket Proxy' },
            }
          )
      end
    end
  end
end
