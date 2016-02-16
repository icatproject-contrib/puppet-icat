require 'spec_helper_acceptance'

# Possible options are listed here:
# https://github.com/puppetlabs/beaker/blob/master/lib/beaker/dsl/helpers/puppet_helpers.rb#L325
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
  # By having the tmp directory inside the shared Vagrant directory,
  # our downloads will persist between runs of the accetance tests
  # -- even "clean" runs.  This will make them a lot quicker as we
  # won't have to repeatedly download the JDK, GlassFish, or the ICAT
  # components ...
  @file { '/vagrant/.tmp': ensure => 'directory' }
  # ... We still want to use /tmp as our "working directory", though.
  @file { '/tmp': ensure => 'directory' }

  @package { 'wget': ensure => installed }
  @class { 'maven::maven': }
  @package { 'python-suds': ensure => installed }

  include '::mysql::server'

  firewall { '100 allow glassfish':
    chain   => 'INPUT',
    state   => ['NEW'],
    dport   => ['4848', '4880', '4881'],
    proto   => 'tcp',
    action  => 'accept',
  }

  file { '/home/vagrant/icat':
    ensure => 'directory',
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->
  file { '/home/vagrant/icat/bin':
    ensure => 'directory',
    owner  => 'vagrant',
    group  => 'vagrant',
  }
  ->
  mysql::db { icat:
    user     => 'username',
    password => 'password',
  }
  ->
  class { 'icat':
    appserver_admin_master_password => 'adminadmin',
    appserver_admin_password        => 'changeit',
    appserver_admin_port            => 4848,
    appserver_install_dir           => '/usr/local/',
    appserver_group                 => 'vagrant',
    appserver_user                  => 'vagrant',

    bin_dir                         => '/home/vagrant/icat/bin',

    components                      => [{
        name    => 'authn_db',
        version => '1.1.2',
      }, {
        name               => 'authn_ldap',
        version            => '1.1.0',
        provider_url       => 'ldap://data.sns.gov:389',
        security_principal => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
      }, {
        'name'        => 'authn_simple',
        'version'     => '1.0.1',
        'credentials' => {
          'user_a' => 'password_a',
          'user_b' => 'password_b',
        },
      }, {
        'name'        => 'icat.server',
        'version'     => '4.5.0',
        'crud_access_usernames' => ['user_a', 'user_b'],
      }
    ],

    db_name                         => 'icat',
    db_password                     => 'password',
    db_type                         => 'mysql',
    db_url                          => 'jdbc:mysql://localhost:3306/icat',
    db_username                     => 'username',

    manage_java                     => true,

    tmp_dir                         => '/vagrant/.tmp',
    working_dir                     => '/tmp',
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
      # TODO: Change this to be more like test at:
      # https://github.com/gdhbashton/puppet-consul_template/blob/master/spec/acceptance/class_spec.rb
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
