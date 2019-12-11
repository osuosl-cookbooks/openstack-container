# execute 'create public network' do
#   command <<-EOF
#     source /root/openrc
#     openstack network create --share --provider-network-type=flat --provider-physical-network=public \
#       --external --default public
#     openstack subnet create public --network public --subnet-range=10.10.1.0/24 \
#       --allocation-pool=start=10.10.1.2,end=10.10.1.100 --gateway 10.10.1.1
#     openstack network set --external public
#     openstack network show -c id -f value public > /var/tmp/public_network
#   EOF
#   creates '/var/tmp/public_network'
# end

execute 'create private network' do
  command <<-EOF
    source /root/openrc
    openstack network create private
    openstack subnet create private --network private --subnet-range=10.20.1.0/24 \
      --allocation-pool=start=10.20.1.2,end=10.20.1.100 --gateway 10.20.1.1
    openstack network show -c id -f value private > /var/tmp/private_network
  EOF
  creates '/var/tmp/private_network'
end
