## About

A Puppet module to download, install and configure an instance of ICAT.

## Requirements

`[TODO]`

## Usage Example

```ruby
# TODO
```

## Development

### Finding Your Way Around

This module follows the standard conventions for [directory structure as per the official PuppetLabs documentation](https://docs.puppetlabs.com/puppet/latest/reference/modules_fundamentals.html#module-layout).

### Commands

Some typical commands for running the automated tests:

```bash
# Install necessary gems for the first time.  I can't get beaker to work properly without using
# sudo here.  (Even using "--path ~/.gem" only gets me so far.)  This may have something to do
# with how/where Ruby is installed on my Mac.
sudo bundle install

# Run unit tests and linters, using bundle to make sure all necessary gems are available.
bundle exec rake test

# Run all acceptance tests, which uses beaker (which in turn uses a whole bunch of stuff...) to
# fire up a VM to run the tests on.  Not for the faint of heart, this one.
export BEAKER_debug=yes
bundle exec rake acceptance

# Run the acceptance tests, but don't destroy any VMs either before or afterwards.  Useful if you
# want to make quick, successive changes and see how they effect things without having to fully
# recreate and provision a VM everytime.  Just bear in mind you won't be starting with a "fresh"
# VM so it's an 'incremental' rather than 'clean' build.
#
# See https://github.com/puppetlabs/beaker-rspec for more info.
export BEAKER_provision=no
export BEAKER_destroy=no
bundle exec rake acceptance

# Undo the ENV vars:
export BEAKER_provision=yes
export BEAKER_destroy=yes

# SSH on to the Beaker VM (assuming it has not been destroyed as above) to have a poke around.
# Note that Beaker uses Vagrant, and it nests the Vagrantfile in a hidden dot directory.
cd .vagrant/beaker_vagrant_files/[node].yml/
vagrant ssh
```
