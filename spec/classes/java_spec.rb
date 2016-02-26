require 'spec_helper'

describe 'icat::java' do
  let :pre_condition do
    "@package { 'wget': ensure => installed } @file { '/tmp': ensure => 'directory' }"
  end

  describe 'with reasonable tmp_dir param value' do
    let :params do
      {'tmp_dir' => '/tmp'}
    end

    it 'should compile' do
      should compile.with_all_deps()

      should create_class('icat::java')
    end

    it 'should require the tmp_dir to download java' do
      should contain_exec('download_jdk').that_requires('File[/tmp]')
    end

    it 'should download and install a jdk package' do
      should contain_package('jdk.x86_64').with({
        'ensure' => 'installed',
        'source' => '/tmp/jdk-7u79-linux-x64.rpm',
      }).that_requires('Exec[download_jdk]')
    end
  end
  context 'with local jdk rpm specified' do
    let :params do
      {
        'group'        => 'group',
        'jdk_rpm_path' => 'puppet:///modules/icatfiles/jdk-7u79-linux-x64.rpm',
        'tmp_dir'      => '/tmp',
        'user'         => 'user',
      }
    end

    it do
      should contain_file('/tmp/jdk-7u79-linux-x64.rpm').with({
        'ensure' => 'file',
        'source' => 'puppet:///modules/icatfiles/jdk-7u79-linux-x64.rpm',
        'owner'  => 'user',
        'group'  => 'group',
      })
      should contain_package('jdk.x86_64').with({
        'ensure' => 'installed',
        'source' => '/tmp/jdk-7u79-linux-x64.rpm',
      }).that_requires('File[/tmp/jdk-7u79-linux-x64.rpm]')
    end
  end
end
