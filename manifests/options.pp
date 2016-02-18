# == Class: options
#
# A class which is basically a collection of GlassFish and JVM options,
# that makes resource relationships and specs a little less painful.
class icat::options (
  $asadmin_user = undef,
  $user         = undef,
) {
  # lint:ignore:variable_scope
  # lint:ignore:quoted_booleans
  # lint:ignore:ensure_first_param
  jvmoption { 'Remove default -Xmx' :
    asadminuser => $asadmin_user,
    ensure      => 'absent',
    option      => '-Xmx512m',
    user        => $user,
  }
  jvmoption { 'Add new -Xmx' :
    asadminuser => $asadmin_user,
    ensure      => 'present',
    option      => '-Xmx1024m',
    user        => $user,
  }
  jvmoption { 'Add -XX:PermSize' :
    asadminuser => $asadmin_user,
    ensure      => 'present',
    option      => '-XX:PermSize=64m',
    user        => $user,
  }
  jvmoption { 'Add -XX:OnOutOfMemoryError' :
    asadminuser => $asadmin_user,
    ensure      => 'present',
    option      => '-XX:OnOutOfMemoryError=\"kill -9 %p\"',
    user        => $user,
  }

  set { 'server.http-service.access-log.format':
    asadminuser => $asadmin_user,
    ensure      => 'present',
    user        => $user,
    value       => '"common"',
  }
  set { 'server.http-service.access-logging-enabled':
    asadminuser => $asadmin_user,
    ensure      => 'present',
    user        => $user,
    value       => 'true',
  }
  set { 'server.thread-pools.thread-pool.http-thread-pool.max-thread-pool-size':
    asadminuser => $asadmin_user,
    ensure      => 'present',
    user        => $user,
    value       => '128',
  }
  set { 'configs.config.server-config.cdi-service.enable-implicit-cdi':
    asadminuser => $asadmin_user,
    ensure      => 'present',
    user        => $user,
    value       => 'false',
  }
  set { 'server.ejb-container.property.disable-nonportable-jndi-names':
    asadminuser => $asadmin_user,
    ensure      => 'present',
    user        => $user,
    value       => 'true',
  }
  set { 'configs.config.server-config.network-config.protocols.protocol.http-listener-2.http.request-timeout-seconds':
    asadminuser => $asadmin_user,
    ensure      => 'present',
    user        => $user,
    value       => '-1',
  }
  # lint:endignore
  # lint:endignore
  # lint:endignore
}
