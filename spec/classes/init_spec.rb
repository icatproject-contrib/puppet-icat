require 'spec_helper'

describe 'icat' do
  let :pre_condition do
    <<-EOS
    @class { 'maven::maven': }
    @package { 'wget': ensure => installed }
    @file { '/tmp': ensure => 'directory' }
    @package { 'python-suds': ensure => installed }
    EOS
  end

  let :facts do
    { :osfamily => 'RedHat' }
  end

  context 'basic' do

    let :params do
      {
        'appserver_admin_password'        => 'p4ssw0rd',
        'appserver_admin_master_password' => 'master_p4ssw0rd',
      }
    end

    describe 'with default/reasonable param values' do
      it 'should compile' do
        should compile.with_all_deps()

        should create_class('icat')
      end

      it 'should create icat::appserver which should use icat::java' do
        should contain_class('icat::appserver').that_requires('Class[icat::java]')
      end
    end

    describe 'set to not manage java' do
      let :params do
        {'manage_java' => 'false'}
      end

      it 'should not create icat::java class' do
        should contain_class('icat::java') == 'false'
      end
    end
  end

  context 'authn_db component selected' do
    let(:params) do
      {
        'appserver_admin_master_password' => 'adminadmin',
        'appserver_admin_password'        => 'changeit',
        'appserver_admin_port'            => 4848,
        'appserver_install_dir'           => '/usr/local/',
        'appserver_group'                 => '',
        'appserver_user'                  => 'root',

        'components'                      => [{
          'name'    => 'authn_db',
          'version' => '1.1.2',
        }],

        'db_name'                         => 'icat',
        'db_password'                     => 'password',
        'db_type'                         => 'mysql',
        'db_url'                          => 'jdbc:mysql://localhost:3306/icat',
        'db_username'                     => 'username',

        'manage_java'                     => true,

        'tmp_dir'                         => '/tmp',
        'working_dir'                     => '/tmp',
      }
    end

    it do
      should contain_icat__create_component('authn_db').with({
        'component_name'  => 'authn_db',
        'patches'         => {
          'setup_utils.py' => 'puppet:///modules/icat/patches/authn_db_setup_utils.patch',
        },
        'templates'       => [
          'icat/authn_db-setup.properties.epp',
          'icat/authn_db.properties.epp',
        ],
        'template_params' => {
          'db_name'               => 'icat',
          'db_password'           => 'password',
          'db_type'               => 'mysql',
          'db_url'                => 'jdbc:mysql://localhost:3306/icat',
          'db_username'           => 'username',
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
        },
        'version'         => '1.1.2',
      })
    end
  end

  context 'unrecognised component name' do
    let(:params) do
      {
        'components' => [{
          'name'    => 'does_not_exist',
          'version' => '1.1.2',
        }],
      }
    end

    it { is_expected.to compile.and_raise_error(/Unrecognised component: does_not_exist/) }
  end
end
