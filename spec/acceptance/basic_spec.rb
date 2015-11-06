require 'spec_helper_acceptance'

apply_manifest_opts = {
  :catch_failures => true,
  # It's really wierd how this is necessary.  If we don't use this option,
  # then the underlying call to puppet apply will not pick up the required
  # modules.  Surely this cannot be standard practice, so I'm classing this as a
  # workaround, but it's not quite clear exactly what's being worked around...
  :modulepath     => '/etc/puppetlabs/puppet/modules/',
}

default_pp = <<-EOS
  @package { 'wget': ensure => installed } @file { '/tmp': ensure => 'directory' }
  class { 'icat':
    appserver_admin_password        => 'p4ssw0rd',
    appserver_admin_master_password => 'master_p4ssw0rd',
  }
EOS

describe 'the icat class' do
  describe 'given default params' do
    before :all do
      apply_manifest(default_pp, apply_manifest_opts)
    end

    it 'should be idempotent' do
      # I.e. we should be able to run it twice without having it fall over.
      expect(apply_manifest(default_pp, apply_manifest_opts).exit_code).to be_zero
    end

    it 'should install a jdk' do
      shell('rpm -q jdk.x86_64', :acceptable_exit_codes => 0)
    end

    it 'should install glassfish' do
      # That asadmin exists and is on the PATH is as good a test as any.
      shell('which asadmin', :acceptable_exit_codes => 0)
    end
  end
end
