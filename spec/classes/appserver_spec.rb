require 'spec_helper'

describe 'icat::appserver' do
  let :pre_condition do
    "@package { 'wget': ensure => installed } @file { '/tmp': ensure => 'directory' }"
  end

  let :facts do
    {
      :osfamily       => 'RedHat',
      :hostname       => 'icat-puppet-test',
      :appserver_path => '/usr/local/glassfish-4.0',
    }
  end

  let :default_params do
    {
      'tmp_dir'               => '/tmp',
      'user'                  => 'username',
      'group'                 => 'groupname',
      'admin_password'        => '/home/pp4/asadmin.pass',
      'admin_password'        => 'p4ssw0rd',
      'admin_master_password' => 'master_p4ssw0rd',
      'admin_user'            => 'user_admin',
      'portbase'              => '4800',
    }
  end

  context 'with reasonable param values and db_type of mysql' do
    let(:params) do
      default_params.merge({
        :db_type => 'mysql'
      })
    end

    it 'should compile' do
      should compile.with_all_deps()

      should create_class('icat::appserver')
    end

    it 'should contain the glassfish class' do
      should contain_class('glassfish')
    end

    it do
      should contain_exec('download_mysql_connector').with({
        'command' => 'wget -v http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.37.zip -O /tmp/mysql-connector-java-5.1.37.zip',
        'path'    => '/usr/bin/',
        'creates' => '/tmp/mysql-connector-java-5.1.37.zip',
      }).that_requires('Package[wget]')
      .that_requires('File[/tmp]')
    end

    it do
      should contain_exec('extract_mysql_connector').with({
        'command' => 'unzip -q -d /tmp /tmp/mysql-connector-java-5.1.37.zip',
        'path'    => '/usr/bin/',
        'unless'  => 'test -d /tmp/mysql-connector-java-5.1.37',
      }).that_requires('Package[unzip]')
      .that_subscribes_to('Exec[download_mysql_connector]')
    end

    it do
      should contain_exec('install_mysql_connector').with({
        'command' => 'cp /tmp/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar /usr/local/glassfish-4.0/glassfish/lib/',
        'path'    => '/usr/bin/',
        'unless'  => 'test -f /usr/local/glassfish-4.0/glassfish/lib/mysql-connector-java-5.1.37-bin.jar',
      }).that_requires('Class[glassfish]')
    end

    it 'should create the icat domain and service' do
      should contain_glassfish__create_domain('icat').with({
        'create_service' => 'true',
      }).that_requires('Class[glassfish]')
    end

    it do
      should contain_class('icat::options').with({
        'asadmin_user' => 'user_admin',
        'user'         => 'username',
      }).that_requires('Glassfish::Create_Domain[icat]')
    end

    it do
      should contain_class('icat::certs').with({
        'hostname' => 'icat-puppet-test',
      }).that_requires('Class[icat::options]')
    end
  end

  context 'with a db_type param of oracle and no connector_jar_path set' do
    let(:params) do
      default_params.merge({
        :db_type => 'oracle'
      })
    end

    it do
      should compile.and_raise_error(/If \"oracle\" is specified as a db_type/)
    end
  end

  context 'with any db_type param and a connector_jar_path set' do
    let(:params) do
      default_params.merge({
        :db_type            => 'oracle',
        :connector_jar_path => 'puppet:///modules/icat/dummy_connector/ojdbc6.jar',
      })
    end

    it do
      should contain_file('/usr/local/glassfish-4.0/glassfish/lib/ojdbc6.jar').with({
        'ensure' => 'file',
        'source' => 'puppet:///modules/icat/dummy_connector/ojdbc6.jar',
        'owner'  => 'username',
        'group'  => 'groupname',
      })
      .that_requires('Class[glassfish]')
    end
  end

  context 'with an unknown database type' do
    let(:params) do
      default_params.merge({
        :db_type => 'DBX'
      })
    end

    it 'should raise an error' do
      should compile.and_raise_error(/Unknown database type of 'DBX'/)
    end
  end
end
