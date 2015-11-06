require 'spec_helper'

describe 'icat' do
  let :pre_condition do
    "@package { 'wget': ensure => installed } @file { '/tmp': ensure => 'directory' }"
  end

  let :facts do
    { :osfamily => 'RedHat' }
  end

  describe 'with default param values' do
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
