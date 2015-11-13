require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/librarian'

require 'fileutils'

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

    install_puppet(:version => '3.8.1')

    # And the plot thickens.  For some reason the symlinking functionality of librarian that
    # symlinks [MODULE_DIR] to [MODULE_DIR]/spec/fixtures/modules/icat/ so that the module
    # is available to the acceptance tests seems to link round and round recursively, once
    # for each run of the tests.  It's not clear what's causing this.  Let's just delete it
    # here to make sure we're starting afresh each time.
    icat_symlink = File.join(module_root, 'spec', 'fixtures', 'modules', 'icat')
    FileUtils.rm icat_symlink, :force => true

    install_puppet
    install_librarian
    librarian_install_modules(module_root, 'icat')
  end
end
