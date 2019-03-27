name             'openstack-container'
maintainer       'Oregon State University'
maintainer_email 'chef@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 12.18' if respond_to?(:chef_version)
issues_url       'https://github.com/osuosl-cookbooks/openstack-container/issues'
source_url       'https://github.com/osuosl-cookbooks/openstack-container'
description      'Installs/Configures openstack-container'
long_description 'Installs/Configures openstack-container'
version          '0.1.0'

supports         'centos', '~> 7.0'

depends 'apache2'
depends 'openstack-common'
depends 'openstack-dashboard'
depends 'openstack-identity'
depends 'openstackclient'
depends 'build-essential'
depends 'poise-python'
depends 'git'
depends 'docker'
