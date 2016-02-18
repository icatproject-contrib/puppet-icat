require 'spec_helper'

describe 'icat::options' do
  let :default_params do
    {
      'asadmin_user' => 'admin',
      'user'         => 'user',
    }
  end

  context 'with reasonable default param values' do

    it 'should set JVM options' do
      should contain_jvmoption('Remove default -Xmx').with({
        'asadminuser' => 'asadmin',
        'ensure'      => 'absent',
        'option'      => '-Xmx512m',
        'user'        => 'user',
      })
      should contain_jvmoption('Add new -Xmx').with({
        'asadminuser' => 'asadmin',
        'ensure'      => 'present',
        'option'      => '-Xmx1024m',
        'user'        => 'user',
      })
      should contain_jvmoption('Add -XX:PermSize').with({
        'asadminuser' => 'asadmin',
        'ensure'      => 'present',
        'option'      => '-XX:PermSize=64m',
        'user'        => 'user',
      })
      should contain_jvmoption('Add -XX:OnOutOfMemoryError').with({
        'asadminuser' => 'asadmin',
        'ensure'      => 'present',
        'option'      => '-XX:OnOutOfMemoryError=\"kill -9 %p\"',
        'user'        => 'user',
      })
    end

    it 'should set GlassFish settings' do
      should contain_set('server.http-service.access-log.format').with({
        'asadminuser' => 'admin',
        'ensure'      => 'present',
        'user'        => 'user',
        'value'       => '"common"',
      })
      should contain_set('server.http-service.access-logging-enabled').with({
        'asadminuser' => 'admin',
        'ensure'      => 'present',
        'user'        => 'user',
        'value'       => 'true',
      })
      should contain_set('server.thread-pools.thread-pool.http-thread-pool.max-thread-pool-size').with({
        'asadminuser' => 'admin',
        'ensure'      => 'present',
        'user'        => 'user',
        'value'       => '128',
      })
      should contain_set('configs.config.server-config.cdi-service.enable-implicit-cdi').with({
        'asadminuser' => 'admin',
        'ensure'      => 'present',
        'user'        => 'user',
        'value'       => 'false',
      })
      should contain_set('server.ejb-container.property.disable-nonportable-jndi-names').with({
        'asadminuser' => 'admin',
        'ensure'      => 'present',
        'user'        => 'user',
        'value'       => 'true',
      })
      should contain_set('configs.config.server-config.network-config.protocols.protocol.http-listener-2.http.request-timeout-seconds').with({
        'asadminuser' => 'admin',
        'ensure'      => 'present',
        'user'        => 'user',
        'value'       => '-1',
      })
    end
  
  end
end