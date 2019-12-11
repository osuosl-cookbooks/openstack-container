require_relative '../../spec_helper'

describe 'openstack-container::identity_registration' do
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
      connection = {
        openstack_api_key: 'admin-pass',
        openstack_auth_url: 'http://127.0.0.1:5000/v3',
        openstack_domain_name: 'default',
        openstack_project_name: 'admin',
        openstack_username: 'admin',
      }

      it do
        expect(chef_run).to create_openstack_service('zun')
          .with(
            type: 'container',
            connection_params: connection
          )
      end
      it do
        expect(chef_run).to create_openstack_endpoint('container-public')
          .with(
            endpoint_name: 'container',
            service_name: 'zun',
            interface: 'public',
            url: 'http://127.0.0.1:9517/v1',
            region: 'RegionOne',
            connection_params: connection
          )
      end
      it do
        expect(chef_run).to create_openstack_endpoint('container-internal')
          .with(
            endpoint_name: 'container',
            service_name: 'zun',
            interface: 'internal',
            url: 'http://127.0.0.1:9517/v1',
            region: 'RegionOne',
            connection_params: connection
          )
      end
      it do
        expect(chef_run).to create_openstack_project('service').with(connection_params: connection)
      end
      it do
        expect(chef_run).to create_openstack_user('kuryr')
          .with(
            domain_name: 'Default',
            role_name: 'admin',
            project_name: 'service',
            password: 'kuryr-pass',
            connection_params: connection
          )
      end
      it do
        expect(chef_run).to grant_role_openstack_user('kuryr')
          .with(
            domain_name: 'Default',
            role_name: 'admin',
            project_name: 'service',
            password: 'kuryr-pass',
            connection_params: connection
          )
      end
      it do
        expect(chef_run).to create_openstack_user('zun')
          .with(
            domain_name: 'Default',
            role_name: 'admin',
            project_name: 'service',
            password: 'zun-pass',
            connection_params: connection
          )
      end
      it do
        expect(chef_run).to grant_role_openstack_user('zun')
          .with(
            domain_name: 'Default',
            role_name: 'admin',
            project_name: 'service',
            password: 'zun-pass',
            connection_params: connection
          )
      end
    end
  end
end
