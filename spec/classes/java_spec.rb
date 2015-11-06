require 'spec_helper'

describe 'icat::java' do
  let :pre_condition do
    "@package { 'wget': ensure => installed } @file { '/tmp': ensure => 'directory' }"
  end
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
    }).that_requires('Exec[download_jdk]')
  end
end
