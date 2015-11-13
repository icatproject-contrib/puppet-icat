require 'spec_helper'

describe 'icat::create_component' do
  let :pre_condition do
    <<-EOS
    @class { 'maven::maven': }
    @package { 'wget': ensure => installed }
    @file { '/tmp': ensure => 'directory' }
    @package { 'python-suds': ensure => installed }
    include icat
    EOS
  end

  let(:facts) { {
    :osfamily => 'RedHat'
  } }

  let (:default_params) do
    {
      'component_name'  => 'icat.server',
      'patches'         => {
        'setup_utils.py' => '/tmp/patches/icat.server/setup_utils.py.patch',
      },
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

    it do
      should contain_file('/tmp/icat.server-4.5.0-distro/icat.server/setup_utils.py.patch').with({
        'source'  => '/tmp/patches/icat.server/setup_utils.py.patch',
        'require' => 'File[/tmp/icat.server-4.5.0-distro]',
      })
    end

    it do
      should contain_exec('apply_icat.server_setup_utils.py_patch').with({
        'command' => 'patch /tmp/icat.server-4.5.0-distro/icat.server/setup_utils.py /tmp/icat.server-4.5.0-distro/icat.server/setup_utils.py.patch',
        'path'    => '/usr/bin/',
        'unless'  => 'patch -R --dry-run /tmp/icat.server-4.5.0-distro/icat.server/setup_utils.py /tmp/icat.server-4.5.0-distro/icat.server/setup_utils.py.patch',
      }).that_subscribes_to('File[/tmp/icat.server-4.5.0-distro/icat.server/setup_utils.py.patch]')
    end

    it do
      should contain_exec('configure_icat.server_setup_script').with({
        'command' => 'python setup CONFIGURE',
        'path'    => '/usr/bin/',
        'cwd'     => '/tmp/icat.server-4.5.0-distro/icat.server',
        'user'    => 'root',
        'group'   => 'root',
      }).that_subscribes_to('File[/tmp/icat.server-4.5.0-distro/icat.server/test.properties]')
      .that_subscribes_to('Exec[apply_icat.server_setup_utils.py_patch]')
    end

    it do
      should contain_exec('run_icat.server_setup_script').with({
        'command' => 'python setup INSTALL',
        'path'    => '/usr/bin/',
        'cwd'     => '/tmp/icat.server-4.5.0-distro/icat.server',
        'user'    => 'root',
        'group'   => 'root',
      }).that_subscribes_to('Exec[configure_icat.server_setup_script]')
    end
  end
end
