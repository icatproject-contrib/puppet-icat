#!/usr/bin/env ruby

source "https://rubygems.org"

gem 'rake'
gem 'puppet'

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

# Syck has been removed in later versions of Ruby, so explicitly install
# it here.
# (https://github.com/dtao/safe_yaml/issues/76#issuecomment-94201296)
gem 'syck' if RUBY_VERSION >= '2.0'
