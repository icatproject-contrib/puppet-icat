require 'spec_helper'

describe 'icat::appserver' do
  let :facts do
    { :osfamily => 'RedHat' }
  end

  let :default_params do
    {
      'tmp_dir'               => '/tmp',
      'user'                  => 'username',
      'group'                 => 'groupname',
      'admin_password'        => 'p4ssw0rd',
      'admin_master_password' => 'master_p4ssw0rd',
    }
  end

  context 'with reasonable param values and db_type of oracle' do
    let(:params) do
      default_params.merge({
        :db_type => 'oracle'
      })
    end

    it 'should compile' do
      should compile.with_all_deps()

      should create_class('icat::appserver')
    end

    it 'should contain the glassfish class' do
      should contain_class('glassfish')
    end

    it 'should install the Oracle connector jar' do
      should contain_glassfish__install_jars('ojdbc6.jar')
        .that_requires('Class[glassfish]')
    end

    it 'should create the icat domain and service' do
      should contain_glassfish__create_domain('icat').with({
        'create_service' => 'true',
      }).that_requires('Class[glassfish]')
    end
  end

  context 'with a db_type param of mysql' do
    let(:params) do
      default_params.merge({
        :db_type => 'mysql'
      })
    end

    it 'should install the MySQL connector jar' do
      should contain_glassfish__install_jars('mysql-connector-java-5.1.36-bin.jar')
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
