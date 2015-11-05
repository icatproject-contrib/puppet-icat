require 'spec_helper_acceptance'

apply_manifest_opts = {
  :catch_failures => true,
  # It's really wierd how this is necessary.  If we don't use this option,
  # then the underlying call to puppet apply will not pick up the required
  # modules.  Surely this cannot be standard practice, so I'm classing this as a
  # workaround, but it's not quite clear exactly what's being worked around...
  :modulepath     => '/etc/puppetlabs/puppet/modules/',
}

describe 'icat::init class' do
  describe 'running puppet code' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'icat': }
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, apply_manifest_opts)
      expect(apply_manifest(pp, apply_manifest_opts).exit_code).to be_zero
    end
  end
end
