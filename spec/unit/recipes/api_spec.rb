require_relative '../../spec_helper'

describe 'openstack-container::api' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'identity_stubs'
      include_context 'container_stubs'
      before do
        allow(IO).to receive(:read).and_call_original
        allow(IO).to receive(:read).with('/var/chef/cache/zun/zun/api/app.wsgi').and_yield('foo')
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(
        openstack-common::etcd
        openstack-container::common
        apache2
        apache2::mod_wsgi
      ).each do |r|
        it do
          expect(chef_run).to include_recipe(r)
        end
      end
      it do
        expect(chef_run).to create_template('/etc/zun/api-paste.ini')
          .with(
            source: 'api-paste.ini.erb',
            owner: 'zun',
            group: 'zun',
            mode: '0644'
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/etc/zun/policy.json')
          .with(
            owner: 'root',
            group: 'zun',
            mode: '0640'
          )
      end
      it do
        expect(chef_run).to run_execute('zun-db-manage upgrade')
          .with(
            command: '/opt/osc-zun/bin/zun-db-manage upgrade',
            user: 'zun',
            group: 'zun'
          )
      end
      it do
        expect(chef_run).to create_directory('/var/www/html/zun')
          .with(
            owner: 'root',
            group: 'root',
            mode: 0o0755
          )
      end
      #      it do
      #        expect(chef_run).to create_file('/var/www/html/zun/app')
      #          .with(
      #            content: 'foo',
      #            owner: 'root',
      #            group: 'root',
      #            mode: 0o0755
      #          )
      #      end
      [
        /^# This file is automatically generated by Chef$/,
        /^# Any changes will be overwritten$/,
        /<VirtualHost 127.0.0.1:9517>$/,
        %r{WSGIDaemonProcess zun-api processes=2 threads=10 user=zun group=zun display-name=%\{GROUP\} python-home=/opt/osc-zun$},
        /WSGIProcessGroup zun-api$/,
        %r{WSGIScriptAlias / /var/www/html/zun/app$},
        %r{ErrorLog /var/log/httpd/zun-api_error.log},
        %r{CustomLog /var/log/httpd/zun-api_access.log combined},
        %r{<Directory /var/www/html/zun},
        %r{WSGISocketPrefix /var/run/httpd},
      ].each do |line|
        it do
          expect(chef_run).to render_file('/etc/httpd/sites-available/zun-api.conf').with_content(line)
        end
      end
      it do
        expect(chef_run.template('/etc/httpd/sites-available/zun-api.conf')).to \
          notify('execute[Clear zun apache restart]').to(:run).immediately
      end
      it do
        expect(chef_run).to enable_service('zun-api').with(service_name: 'httpd')
      end
      it do
        expect(chef_run).to start_service('zun-api').with(service_name: 'httpd')
      end
      it do
        expect(chef_run).to run_execute('zun apache restart')
          .with(
            command: 'touch /var/chef/cache/zun-apache-restarted',
            creates: '/var/chef/cache/zun-apache-restarted'
          )
      end
      it do
        expect(chef_run.execute('zun apache restart')).to notify('service[zun-api]').to(:restart).immediately
      end
      it do
        expect(chef_run.service('zun-api')).to subscribe_to('template[/etc/zun/zun.conf]').on(:restart)
      end
    end
  end
end
