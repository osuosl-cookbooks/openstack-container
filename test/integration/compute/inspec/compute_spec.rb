# # encoding: utf-8

# Inspec test for recipe openstack-container::compute

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/
describe file '/etc/zun/rootwrap.conf' do
  its('group') { should eq 'zun' }
  its('mode') { should cmp '0640' }
end

describe directory '/etc/zun/rootwrap.d' do
  its('owner') { should eq 'zun' }
  its('group') { should eq 'zun' }
  its('mode') { should cmp '0750' }
end

describe file '/etc/zun/rootwrap.d/zun.filters' do
  its('group') { should eq 'zun' }
  its('mode') { should cmp '0640' }
end

describe command 'sudo -l -U zun' do
  its('stdout') { should match %r{\(ALL\) NOPASSWD: /opt/osc-zun/bin/zun-rootwrap /etc/zun/rootwrap\.conf \*} }
  its('stdout') { should match %r{secure_path=/sbin\\:/bin\\:/usr/sbin\\:/usr/bin, secure_path=/opt/osc-zun/bin\\:/sbin\\:/bin\\:/usr/sbin\\:/usr/bin,} }
  its('stdout') { should match match /!requiretty/ }
end

describe docker.info do
  its('ClusterStore') { should cmp 'etcd://127.0.0.1:2379' }
end

describe ini '/etc/systemd/system/docker-zun.service' do
  its('Service.ExecStart') { should cmp '/usr/bin/dockerd  --cluster-store=etcd://127.0.0.1:2379 --group=zun --host tcp://127.0.0.1:2375 --host unix:///var/run/docker.sock --pidfile=/var/run/docker-zun.pid --containerd=/run/containerd/containerd.sock' }
end

describe port(2375) do
  it { should be_listening }
  its('processes') { should include 'dockerd' }
end

describe service 'docker-zun' do
  it { should be_enabled }
  it { should be_running }
end

describe ini '/etc/systemd/system/zun-compute.service' do
  its('Unit.Description') { should cmp 'OpenStack Container Service Compute Agent' }
  its('Service.Environment') { should cmp 'PATH=/opt/osc-zun/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin' }
  its('Service.ExecStart') { should cmp '/opt/osc-zun/bin/zun-compute' }
  its('Service.User') { should cmp 'zun' }
  its('Install.WantedBy') { should cmp 'multi-user.target' }
end

describe service 'zun-compute.service' do
  it { should be_enabled }
  it { should be_running }
end

describe command('bash -c "source /root/openrc && openstack appcontainer service list -f value -c Binary -c State"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /^zun-compute up$/ }
end

describe command('bash -c "source /root/openrc && openstack appcontainer host list -f value -c hostname"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /compute/ }
end

describe command('bash -c "source /root/openrc && openstack appcontainer run --name test -f shell cirros uname -a && sleep 10"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /image="cirros"/ }
  its('stdout') { should match /status="Creating"/ }
  its('stdout') { should match /command="\[u'uname', u'-a'\]"/ }
end

describe command('bash -c "source /root/openrc && openstack appcontainer logs test"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /Linux/ }
end

describe command('bash -c "source /root/openrc && openstack appcontainer show test -f shell"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /status="Stopped"/ }
end

describe command('bash -c "source /root/openrc && openstack appcontainer delete test"') do
  its('exit_status') { should eq 0 }
  its('stdout') { should match /Request to delete container test has been accepted./ }
end
