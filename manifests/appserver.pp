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
  $connector_jar_path    = undef,
) {
  $asadmin_user = 'admin'
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
    asadmin_user            => $asadmin_user, # TODO: Should be $user?
    asadmin_passfile        => "/home/${user}/asadmin.pass",
    asadmin_master_password => 'changeit',   # TODO: Should be $admin_master_password
    asadmin_password        => 'adminadmin', # TODO: Should be $admin_password
    create_passfile         => true,
  }

  if $connector_jar_path == undef {
    case $db_type {
      # MySQL is the only DB type supported where you don't have to specify your own connector jar.
      'mysql' : {
        realize( Package['wget'] )
        realize( Package['unzip'] )
        realize( File[$tmp_dir] )

        $connector_url = 'http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.37.zip'
        $connector_zip_path = "${tmp_dir}/mysql-connector-java-5.1.37.zip"
        $connector_extracted_path = "${tmp_dir}/mysql-connector-java-5.1.37"

        exec { 'download_mysql_connector':
          command => "wget -v ${connector_url} -O ${connector_zip_path}",
          path    => '/usr/bin/',
          creates => $connector_zip_path,
          require => [
            Package['wget'],
            File[$tmp_dir],
          ]
        } ~>
        exec { 'extract_mysql_connector':
          command => "unzip -q -d ${tmp_dir} ${connector_zip_path}",
          path    => '/usr/bin/',
          unless  => "test -d ${connector_extracted_path}",
          require => [Package['unzip']],
        } ~>
        exec { 'install_mysql_connector':
          command => "cp ${connector_extracted_path}/mysql-connector-java-5.1.37-bin.jar ${::appserver_path}/glassfish/lib/",
          path    => '/usr/bin/',
          unless  => "test -f ${::appserver_path}/glassfish/lib/mysql-connector-java-5.1.37-bin.jar",
          require => Class['glassfish'],
        }
      }

      'oracle' : {
        fail('If "oracle" is specified as a db_type, you *must* also specify a path to a connector jar.')
      }

      default : {
        fail("Unknown database type of '${db_type}'. Please use either 'oracle' or 'mysql'.")
      }
    }
  } else {
    $connector_basename = basename($connector_jar_path)
    file { "${::appserver_path}/glassfish/lib/${connector_basename}":
      ensure => 'file',
      source => $connector_jar_path
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
  ->
  class { 'icat::options':
    asadmin_user => $asadmin_user,  # TODO: Should be $user?
    user         => $user,
  }
  ->
  class { 'icat::certs':
    keystore_path    => "${::icat_domain_path}/config/keystore.jks",
    cert_path        => "${::icat_domain_path}/config/s1as-export.jks",
    cacerts_path     => "${::java_security_path}/cacerts",
    jssecacerts_path => "${::java_security_path}/jssecacerts",
    keytool_path     => $::java_keytool_path,
    hostname         => $::hostname,
  }
}
