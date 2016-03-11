#!/usr/bin/env ruby

source "https://rubygems.org"

if ENV.key?('PUPPET_VERSION')
  puppetversion = ENV['PUPPET_VERSION']
else
  # For now, default to version used at ORNL.
  puppetversion = '~> 4.3.2'
end

gem 'rake'
gem 'puppet', puppetversion

gem 'librarian-puppet'

gem 'rspec'
gem 'rspec-puppet'
gem 'puppetlabs_spec_helper'
gem 'puppet-lint', :git => 'https://github.com/rodjek/puppet-lint.git'
gem 'puppet-syntax'

gem "beaker"
gem 'beaker-librarian'
gem "beaker-rspec"
# TODO: Remove this?  Might not be necessary.
gem "vagrant-wrapper"
