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
    # Install a database connector jar based on the chosen DB type.  Using the install_jars definition
    # inside the glassfish module would seem to be the best thing to do here, but for some reason the
    # connector jars need to be placed in glassfish/lib rather than glassfish/lib/ext.  See:
    # http://stackoverflow.com/questions/10965926/deploying-to-glassfish-classpath-not-set-for-com-mysql-jdbc-jdbc2-optional-mysql
    # Unfortunately, the install_jars definition will only install to lib/ext, so use plain old file
    # resources instead.
    #
    # Also note that we're trying to avoid just bundling the jars with the code, since there
    # seems to be licensing issues with doing so (definitely in the case of Oracle, possibly
    # in the case of MySQL).  Hence the messy execs here.  Perhaps the long term solution is
    # to allow for Puppet file-server functionality from master.  See this for an example of
    # how this might work given a Vagrant installation:
    #
    # https://theholyjava.wordpress.com/2012/06/14/serving-files-with-puppet-standalone-in-vagrant-from-the-puppet-uris/

    'oracle' : {
      fail("A database type of 'oracle' is not yet supported.")
    }
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
        command => "cp ${connector_extracted_path}/mysql-connector-java-5.1.37/mysql-connector-java-5.1.37-bin.jar ${::appserver_path}/glassfish/lib/",
        path    => '/usr/bin/',
        unless  => "test -d ${::appserver_path}/glassfish/lib/mysql-connector-java-5.1.37-bin.jar",
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
