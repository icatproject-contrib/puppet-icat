# == Class: appserver
#
# A class to manage the application server used by ICAT.  To start with this will be just GlassFish,
# but it could be expanded to provide a WildFly alternative option.
class icat::appserver (
  $tmp_dir               = undef,
  $user                  = undef,
  $group                 = undef,
  $admin_password        = undef,
  $admin_master_password = undef,
  $db_type               = undef,
) {
  package { 'unzip':
    ensure => 'installed'
  }
  ->
  class { 'glassfish':
    # Clear up before we start.
    remove_default_domain   => true,

    # Download and installation properties.
    install_method          => 'zip',
    tmp_dir                 => "${tmp_dir}/glassfish",
    version                 => '4.0',

    # GlassFish account info.
    user                    => $user,
    group                   => $group,
    manage_accounts         => false,

    # We provision our own Oracle JDK installation elsewhere.
    manage_java             => false,

    # Make sure that the binaries are callable.
    add_path                => true,

    # Asadmin properties.
    asadmin_user            => 'admin',      # TODO: Should be $user
    asadmin_passfile        => "/home/${user}/asadmin.pass",
    asadmin_master_password => 'changeit',   # TODO: Should be $admin_master_password
    asadmin_password        => 'adminadmin', # TODO: Should be $admin_password
    create_passfile         => true,
  }

  case $db_type {
    'oracle' : {
      glassfish::install_jars { 'ojdbc6.jar':
        source  => 'puppet:///modules/icat/ojdbc6.jar',
        require => Class['glassfish'],
      }
    }
    'mysql' : {
      glassfish::install_jars { 'mysql-connector-java-5.1.36-bin.jar':
        source  => 'puppet:///modules/icat/mysql-connector-java-5.1.36-bin.jar',
        require => Class['glassfish'],
      }
    }
    default : {
      fail("Unknown database type of '${db_type}'. Please use either 'oracle' or 'mysql'.")
    }
  }

  glassfish::create_domain { 'icat':
    create_service      => true,
    service_name        => 'icat',
    enable_secure_admin => true,
    start_domain        => true,
    domain_user         => $user,
    require             => Class['glassfish'],
  }
}
