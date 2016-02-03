# `puppet-icat` [![Build Status](https://travis-ci.org/icatproject-contrib/puppet-icat.svg?branch=master)](https://travis-ci.org/icatproject-contrib/puppet-icat)

## About

The aim of this Puppet module is to automate the process of downloading, installing and configuring a full ICAT stack.

The module may be used with Vagrant to provision a VM on your local dev
machine.  Such a VM could be used as a sandbox/testbed for applications
that require an instance of ICAT to be developed against.  Local VMs
provisioned by Puppet could also be used to automate full end-to-end
testing of ICAT itself.

**NOTE: This is a work in progress and as such provisioning actual ICAT deployments in production with this module is not currently possible.  It is, however, certainly a goal of the project.**

## Usage Example

Complete usage examples are to follow at a later date.  (I am working on a manifest to create a full ICAT stack to be used for local development and testing purposes, and this will probably serve as the best possible usage example.  I will likely upload it to a separate repository.)

To give you a basic idea of the syntax, however, consider the following manifest which installs Java and GlassFish, creates an `icat` GlassFish domain, and then installs a single ICAT component (`authn_db`):

```puppet
# Declare necessary directories used by the provisioning process.
@file { '/vagrant/.tmp': ensure => 'directory' }
@file { '/tmp': ensure => 'directory' }

# Make sure various dependenices are met.
@package { 'wget': ensure => installed }
@class { 'maven::maven': }
@package { 'python-suds': ensure => installed }

# Create an empty MySQL server.
include '::mysql::server'
mysql::db { icat:
  user     => 'username',
  password => 'password',
}
->
# Set up GlassFish and the `icat` domain.
class { 'icat':
  appserver_user                  => 'vagrant',
  appserver_group                 => 'vagrant',
  appserver_admin_password        => 'p4ssw0rd',
  appserver_admin_master_password => 'master_p4ssw0rd',
  db_type                         => 'mysql',
  tmp_dir                         => '/vagrant/.tmp',
}
->
# Deploy the `authn_db` component to the `icat` domain.
icat::create_component { 'authn_db':
  patches         => {
    'setup_utils.py' => '/path/to/patches/authn_db_setup_utils.patch',
  },
  templates       => [
    '/path/to/templates/authn_db-setup.properties.epp',
    '/path/to/templates/authn_db.properties.epp',
  ],
  template_params => {
    'db_url'                => 'jdbc:mysql://localhost:3306/icat',
    'db_username'           => 'username',
    'db_password'           => 'password',
    'db_name'               => 'icat',
    'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
    'glassfish_admin_port'  => '4848',
  },
  tmp_dir         => '/vagrant/.tmp',
  working_dir     => '/tmp',
  version         => '1.1.2',
}
```

Note that templates and optional patch files are passed in to the component creation process where necessary.

### Patch Files

Patch files are a way to fix any problems with the setup scripts where a fix has not been released yet.  They are of the standard diff/patch format, for example:

```patch
# '/path/to/patches/authn_db_setup_utils.patch'
212c212
<             result += " --validateatmostonceperiod=60 --validationtable=dual --creationretryattempts=10 --isconnectvalidatereq=true"
---
>             dProps += " --validateatmostonceperiod=60 --validationtable=dual --creationretryattempts=10 --isconnectvalidatereq=true"
```

### Template Files

Template files are a way to populate the `.properties` files used in the ICAT component setup process with values from inside the Puppet manifest.  They are basically plain old `.properties` files with bits of [Embedded Puppet Syntax (EPP)](https://docs.puppetlabs.com/puppet/latest/reference/lang_template_epp.html) embedded in them:

```
# Driver and connection properties for the MySQL database.
driver=com.mysql.jdbc.jdbc2.optional.MysqlDataSource
dbProperties=url="'"<%=$db_url%>"'":user=<%=$db_username%>:password=<%=$db_password%>:databaseName=<%=$db_name%>

# Must contain "glassfish/domains"
glassfish=<%=$glassfish_install_dir%>

# Port for glassfish admin calls (normally 4848)
port=<%=$glassfish_admin_port%>
```

Variables referenced within the EPP are then populated with corresponding name / value pairs passed as a hash to the `template_params` parameter.

## Current Limitations

* Getting the GlassFish module to accept non-default admin passwords was   problematic and so I skipped over this.  Need to revisit before this is ever used in production.

* Oracle databases are not yet supported given the fact that scripting the download of the connector jar directly from Oracle is impossible, and I'm not sure of the legality of redistributing it ourselves.  We therefore need to find a sensible way for the module user to feed it to the module (given that the module has to work in a master/agent setting as well as within a Vagrant VM).

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
