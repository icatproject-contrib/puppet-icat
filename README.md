# `puppet-icat` [![Build Status](https://travis-ci.org/icatproject-contrib/puppet-icat.svg?branch=master)](https://travis-ci.org/icatproject-contrib/puppet-icat)

## About

The aim of this Puppet module is to automate the process of downloading, installing and configuring a full ICAT stack.

The module may be used with Vagrant to provision a VM on your local dev
machine.  Such a VM could be used as a sandbox/testbed for applications
that require an instance of ICAT to be developed against.  Local VMs
provisioned by Puppet could also be used to automate full end-to-end
testing of ICAT itself.

## Usage Example

The following manifest installs a local MySQL database, Java and GlassFish, creates an `icat` GlassFish domain, and then installs several ICAT components:

```puppet
# Declare necessary directories used by the provisioning process.
@file { '/vagrant/.tmp': ensure => 'directory' }
@file { '/tmp': ensure => 'directory' }

# Make sure various dependenices are met.
@package { 'wget': ensure => installed }
@class { 'maven::maven': }
@package { 'python-suds': ensure => installed }

file { '/home/vagrant/icat':
  ensure => 'directory',
  owner  => 'vagrant',
  group  => 'vagrant',
}
->
file { '/home/vagrant/icat/bin':
  ensure => 'directory',
  owner  => 'vagrant',
  group  => 'vagrant',
}
->
# Create an empty MySQL server.
mysql::db { icat:
  user     => 'username',
  password => 'password',
}
->
# Set up GlassFish, the `icat` domain, and then install authn.db,
# authn.simple, authn.ldap and icat.server.
class { 'icat':
  appserver_admin_master_password => 'adminadmin',
  appserver_admin_password        => 'changeit',
  appserver_admin_port            => 4848,
  appserver_install_dir           => '/usr/local/',
  appserver_group                 => 'vagrant',
  appserver_user                  => 'vagrant',

  bin_dir                         => '/home/vagrant/icat/bin',

  components                      => [{
      name    => 'authn.db',
      version => '1.1.2',
    }, {
      name               => 'authn.ldap',
      version            => '1.1.0',
      provider_url       => 'ldap://data.sns.gov:389',
      security_principal => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
    }, {
      name        => 'authn.simple',
      version     => '1.0.1',
      credentials => {
        'user_a' => 'password_a',
        'user_b' => 'password_b',
      },
    }, {
      name                  => 'icat.server',
      version               => '4.5.0',
      crud_access_usernames => ['user_a', 'user_b'],
    }
  ],

  db_name                         => 'icat',
  db_password                     => 'password',
  db_type                         => 'mysql',
  db_url                          => 'jdbc:mysql://localhost:3306/icat',
  db_username                     => 'username',

  manage_java                     => true,

  tmp_dir                         => '/vagrant/.tmp',
  working_dir                     => '/tmp',
}
```

## Development

### Finding Your Way Around

This module follows the standard conventions for [directory structure as per the official PuppetLabs documentation](https://docs.puppetlabs.com/puppet/latest/reference/modules_fundamentals.html#module-layout).

### Setup

Developers will need the following on their machine:

* Ruby and associated Dev Tools
* Bundler
* VirtualBox
* Vagrant

#### Ubuntu 14.04:

```bash
# Install Ruby and other system dependencies.
sudo apt-get install ruby ruby-dev

# From SO answer at http://stackoverflow.com/a/16028181, necessary for nokogiri:
sudo apt-get install libruby ri rdoc irb libxslt-dev libxml2-dev zlib1g-dev
# From SO answer at http://stackoverflow.com/a/16193703, necessary for unf_ext:
sudo apt-get install build-essential

# Use Bundler to install all gems needed by the project.
sudo gem install bundle
bundle install

# Install Virtualbox.
sudo apt-get install virtualbox

# Install Vagrant
#
# NOTE: when trying this out on a fresh VM recently I had to manually
# download and install the latest .deb (1.7.4) from the website as a
# workaround to some strange error I was getting.  This also meant
# uninstalling the latest version of Bundler which had been installed
# above and replacing it with 1.10.5, since 1.10.6 and later is not
# compatible with that version of Vagrant.
sudo apt-get install vagrant

# Run tests to see if everything is working.
bundle exec rake test
bundle exec rake acceptance
```

#### Mac OSX:

```bash
# Use Bundler to install necessary gems.
sudo gem install bundle
sudo bundle install

# Install Vagrant and Virtualbox using homebrew.
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install caskroom/cask/brew-cask
brew cask install virtualbox
brew cask install vagrant
brew cask install vagrant-manager

# Run tests to see if everything is working.
bundle exec rake test
bundle exec rake acceptance
```

#### Windows:

```bash
# TODO: Add Windows setup.  Unfortunately this is not straight forward. :(
```

### Commands

Some typical commands for working with the code:

```bash
# Run unit tests and linters, using bundle to make sure all necessary gems are
# available.
bundle exec rake test

# Run all acceptance tests with debugging output enabled.
export BEAKER_debug=yes
bundle exec rake acceptance

# Run the acceptance tests, but use a particular version of Puppet.
export PUPPET_VERSION=4.2.1
bundle exec rake acceptance

# Run the acceptance tests again, but don't destroy any VMs either before or
# afterwards.  Useful if you want to make quick, successive changes and see
# how they effect things without having to fully recreate and provision a VM
# everytime.  Just bear in mind you
# won't be starting with a "fresh" VM so it's an 'incremental' rather than
# 'clean' build.
#
# See https://github.com/puppetlabs/beaker-rspec for more info.
export BEAKER_provision=no
export BEAKER_destroy=no
bundle exec rake acceptance

# Undo the ENV vars:
export BEAKER_provision=yes
export BEAKER_destroy=yes

# SSH on to the Beaker VM (assuming it has not been destroyed as above) to
# have a poke around.  Note that Beaker uses Vagrant, and it nests the
# Vagrantfile in a hidden dot directory.
cd .vagrant/beaker_vagrant_files/[node].yml/
vagrant ssh
```
