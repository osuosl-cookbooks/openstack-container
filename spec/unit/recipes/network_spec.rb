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
    end
  end
end
