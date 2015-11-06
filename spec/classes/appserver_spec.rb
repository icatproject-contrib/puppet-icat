require 'spec_helper'

describe 'icat::appserver' do
  let :facts do
    { :osfamily => 'RedHat' }
  end

  describe 'with reasonable param values' do
    let :params do
      {
        'tmp_dir'               => '/tmp',
        'user'                  => 'username',
        'group'                 => 'groupname',
        'admin_password'        => 'p4ssw0rd',
        'admin_master_password' => 'master_p4ssw0rd',
      }
    end

    it 'should compile' do
      should compile.with_all_deps()

      should create_class('icat::appserver')
    end

    it 'should contain the glassfish class' do
      should contain_class('glassfish')
    end
  end
end
