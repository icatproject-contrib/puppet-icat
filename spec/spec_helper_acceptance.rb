require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/librarian'

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

    # TODO: Consider the following nice-to-have, which for some reason breaks
    #       breaks the modulepath workaround in the acceptance test file.
    #
    # hosts.each do |host|
    #   # Don't bother re-installing Puppet and librarian if they are already installed,
    #   # which could happen given the BEAKER_provision env var (see /README.md).
    #   # Idea taken from https://github.com/maestrodev/puppet-maven/blob/master/spec/spec_helper_acceptance.rb
    #   unless (ENV['BEAKER_provision'] == 'no')
    #     begin
    #       on host, 'puppet --version'
    #     rescue
    #       install_puppet
    #       install_librarian
    #     end
    #   end
    #   # ... Always (re-)install modules however, since they may have changed.
    #   librarian_install_modules(module_root, 'icat')
    # end

    install_puppet
    install_librarian
    librarian_install_modules(module_root, 'icat')
  end
end
