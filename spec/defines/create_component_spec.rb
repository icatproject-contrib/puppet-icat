require 'spec_helper'

describe 'icat::create_component' do
  let :pre_condition do
    <<-EOS
    @class { 'maven::maven': }
    @package { 'wget': ensure => installed }
    @file { '/tmp': ensure => 'directory' }
    include icat
    EOS
  end

  let(:facts) { {
    :osfamily => 'RedHat'
  } }

  let (:default_params) do
    {
      'component_name'  => 'icat.server',
      'templates'       => [
        'icat/test.properties.epp',
      ],
      'template_params' => {
        'param' => 'value',
      },
      'tmp_dir'         => '/tmp',
      'version'         => '4.5.0',
    }
  end

  context 'with default params' do
    let(:title) { 'icat.server' }
    let(:params) { default_params }

    it do
      should compile.with_all_deps()
    end

    it do
      should contain_maven('/tmp/icat.server-4.5.0-distro.zip').with({
        'groupid'    => 'org.icatproject',
        'artifactid' => 'icat.server',
        'version'    => '4.5.0',
        'classifier' => 'distro',
        'packaging'  => 'zip',
        'repos'      => ['http://www.icatproject.org/mvn/repo'],
        'user'       => 'root',
        'group'      => 'root',
        'require'    => 'Class[Maven::Maven]'
      })
    end

    it do
      should contain_exec('extract_icat.server').with({
        'command' => 'unzip -q -d /tmp/icat.server-4.5.0-distro /tmp/icat.server-4.5.0-distro.zip',
        'path'    => '/usr/bin/',
        'unless'  => 'test -d /tmp/icat.server-4.5.0-distro',
      }).that_subscribes_to('Maven[/tmp/icat.server-4.5.0-distro.zip]')
    end

    it do
      should contain_file('/tmp/icat.server-4.5.0-distro').with({
        'ensure'  => 'directory',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0600',
        'recurse' => true,
      }).that_requires('Exec[extract_icat.server]')
    end

    it do
      should contain_file('/tmp/icat.server-4.5.0-distro/icat.server/test.properties').with({
        'ensure'  => 'present',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0600',
      }).with_content(/This is a string against which we will test./)
      .with_content(/value/)
      .that_requires('File[/tmp/icat.server-4.5.0-distro]')
    end
  end
end
