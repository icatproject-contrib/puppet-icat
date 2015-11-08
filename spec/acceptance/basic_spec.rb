require 'spec_helper_acceptance'

apply_manifest_opts = {
  :catch_failures => true,
  # It's really wierd how this is necessary.  If we don't use this option,
  # then the underlying call to puppet apply will not pick up the required
  # modules.  Surely this cannot be standard practice, so I'm classing this as a
  # workaround, but it's not quite clear exactly what's being worked around...
  :modulepath     => '/etc/puppetlabs/puppet/modules/',
  :debug          => true,
}

default_pp = <<-EOS
  @package { 'wget': ensure => installed } @file { '/tmp': ensure => 'directory' }
  class { 'icat':
    appserver_user                  => 'vagrant',
    appserver_group                 => 'vagrant',
    appserver_admin_password        => 'p4ssw0rd',
    appserver_admin_master_password => 'master_p4ssw0rd',
    appserver_db_type               => 'mysql',
  }
EOS

# https://docs.puppetlabs.com/references/3.4.2/man/agent.html
success_return_code = 0
changes_occured_return_code = 2

describe 'the icat class' do
  describe 'given default params' do
    before :all do
      apply_manifest(default_pp, apply_manifest_opts)
    end

    it 'should be idempotent' do
      # I.e. we should be able to run it twice without having it fall over.
      apply_manifest(default_pp, apply_manifest_opts.merge(
        :acceptable_exit_codes => [success_return_code, changes_occured_return_code]))
    end

    it 'should install a jdk' do
      shell('rpm -q jdk.x86_64', :acceptable_exit_codes => 0)
    end

    it 'should install glassfish' do
      # That asadmin exists and is on the PATH is as good a test as any.
      shell('which asadmin', :acceptable_exit_codes => 0)
    end

    it 'should create an icat domain and service' do
      shell('test -d /usr/local/glassfish-4.0/glassfish/domains/icat/', :acceptable_exit_codes => 0)
      shell('test -f /etc/init.d/icat', :acceptable_exit_codes => 0)
    end

    it 'should have created a security cert against the appropriate hostname' do
      shell('grep "icat-puppet-test" /usr/java/jdk1.7.0_79/jre/lib/security/jssecacerts', :acceptable_exit_codes => 0)
    end
  end
end
