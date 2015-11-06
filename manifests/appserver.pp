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

    # Needs to be a user with permissions to manage home files and folders.
    user                    => $user,
    group                   => $group,
    manage_accounts         => false,

    # We provision our own Oracle JDK installation elsewhere.
    manage_java             => false,

    # Make sure that the binaries are callable.
    add_path                => true,

    # Asadmin properties.
    asadmin_user            => $user,
    asadmin_passfile        => "${tmp_dir}/asadmin.pass",
    asadmin_master_password => $admin_master_password,
    asadmin_password        => $admin_password,
    create_passfile         => true,
  }
}
