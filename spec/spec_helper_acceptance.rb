require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'
require 'beaker/librarian'

require 'fileutils'

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do

    # And the plot thickens.  For some reason the symlinking functionality of librarian that
    # symlinks [MODULE_DIR] to [MODULE_DIR]/spec/fixtures/modules/icat/ so that the module
    # is available to the acceptance tests seems to link round and round recursively, once
    # for each run of the tests.  It's not clear what's causing this.  Let's just delete it
    # here to make sure we're starting afresh each time.
    icat_symlink = File.join(module_root, 'spec', 'fixtures', 'modules', 'icat')
    FileUtils.rm icat_symlink, :force => true

    # See here for possible installation options:
    # https://github.com/puppetlabs/beaker/blob/master/lib/beaker/dsl/install_utils/foss_utils.rb
    install_puppet({
      # TODO: pull this in from env var.
      :version        => '3.8.1',
    })
    install_librarian
    librarian_install_modules(module_root, 'icat')
  end
end
