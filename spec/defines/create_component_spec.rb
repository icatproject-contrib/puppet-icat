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
      'component_name' => 'icat.server',
      'templates'      => [
        "icat.properties.epp",
        "icat-setup.properties.epp",
        "icat.log4j.properties.epp",
      ],
      'tmp_dir'        => '/tmp',
      'version'        => '4.5.0',
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
  end
end
