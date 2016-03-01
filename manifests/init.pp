# == Class: icat
#
# This module manages an entire installation of ICAT.
class icat (
  $appserver_admin_master_password = 'adminadmin',
  $appserver_admin_passfile        = '/tmp/asadmin.pass',
  $appserver_admin_password        = 'changeit',
  $appserver_admin_user            = 'admin',
  $appserver_install_dir           = '/usr/local/',
  $appserver_group                 = 'root',
  $appserver_portbase              = 2200,
  $appserver_user                  = 'root',

  $bin_dir                         = undef,

  $components                      = [],

  $connector_jar_path              = undef,

  $db_name                         = 'icat',
  $db_password                     = 'password',
  $db_type                         = 'mysql',
  $db_url                          = 'jdbc:mysql://localhost:3306/icat',
  $db_username                     = 'username',

  $jdk_rpm_path                    = undef,

  $manage_java                     = true,

  $tmp_dir                         = '/tmp',
  $working_dir                     = '/tmp',
) {
  validate_string($appserver_admin_master_password)
  validate_absolute_path($appserver_admin_passfile)
  validate_string($appserver_admin_password)
  validate_string($appserver_admin_user)
  validate_string($appserver_group)

  validate_integer($appserver_portbase)
  unless $appserver_portbase % 100 == 0 {
    fail("Expected a portbase of the form XX00, but got '${appserver_portbase}'.")
  }

  validate_string($appserver_user)

  validate_array($components)

  if $db_type == 'oracle' {
    validate_string($connector_jar_path)
  }

  unless $db_type =~ /^(oracle|mysql)$/ {
    fail("Unknown database type of '${db_type}'. Please use either 'oracle' or 'mysql'.")
  }

  validate_string($db_name)
  validate_string($db_password)
  validate_string($db_type)
  validate_string($db_url)
  validate_string($db_username)

  validate_bool($manage_java)

  validate_string($tmp_dir)
  validate_string($working_dir)

  $appserver_admin_port = $appserver_portbase + 48

  if $manage_java {
    class { 'icat::java':
      group        => $appserver_group,
      jdk_rpm_path => $jdk_rpm_path,
      tmp_dir      => $tmp_dir,
      user         => $appserver_user,
      before       => Class['icat::appserver'],
    }
  }

  class { 'icat::appserver':
    tmp_dir               => $tmp_dir,
    user                  => $appserver_user,
    group                 => $appserver_group,
    admin_passfile        => $appserver_admin_passfile,
    admin_password        => $appserver_admin_password,
    admin_master_password => $appserver_admin_master_password,
    admin_user            => $appserver_admin_user,
    db_type               => $db_type,
    connector_jar_path    => $connector_jar_path,
    portbase              => $appserver_portbase,
  }
  ->
  Icat::Create_Component <| |>

  # lint:ignore:variable_scope
  $components.each |Integer $index, Hash $component_info| {
    validate_hash($component_info)

    unless has_key($component_info, 'name')    { fail('Component name required.') }
    unless has_key($component_info, 'version') { fail('Component version required.') }

    case $component_info['name'] {
      'authn_db' : {
        icat::create_component { $component_info['name']:
          deployment_order => 80,
          patches          => {
            # See: https://docs.puppetlabs.com/guides/file_serving.html#serving-module-files
            'setup_utils.py' => 'puppet:///modules/icat/patches/authn_db_setup_utils.patch',
          },
          templates        => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/authn_db-setup.properties.epp',
            'icat/authn_db.properties.epp',
          ],
          template_params  => {
            'db_name'               => $db_name,
            'db_password'           => $db_password,
            'db_type'               => $db_type,
            'db_url'                => $db_url,
            'db_username'           => $db_username,
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
          },
          tmp_dir          => $tmp_dir,
          working_dir      => $working_dir,
          version          => $component_info['version'],
        }
      }
      'authn_ldap' : {
        unless has_key($component_info, 'provider_url')       { fail('LDAP provider URL required.') }
        unless has_key($component_info, 'security_principal') { fail('LDAP security principal required.') }

        icat::create_component { $component_info['name']:
          deployment_order => 80,
          templates        => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/authn_ldap-setup.properties.epp',
            'icat/authn_ldap.properties.epp',
          ],
          template_params  => {
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
            'provider_url'          => $component_info['provider_url'],
            'security_principal'    => $component_info['security_principal'],
          },
          tmp_dir          => $tmp_dir,
          working_dir      => $working_dir,
          version          => $component_info['version'],
        }
      }
      'authn_simple' : {
        unless has_key($component_info, 'credentials') { fail('Simple credentials required.') }

        icat::create_component { $component_info['name']:
          deployment_order => 80,
          templates        => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/authn_simple-setup.properties.epp',
            'icat/authn_simple.properties.epp',
          ],
          template_params  => {
            'credentials'           => $component_info['credentials'],
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
          },
          tmp_dir          => $tmp_dir,
          working_dir      => $working_dir,
          version          => $component_info['version'],
        }
      }
      'icat.server' : {
        # https://docs.puppetlabs.com/puppet/latest/reference/lang_collectors.html
        Icat::Create_Component <| title == 'authn_simple' or title == 'authn_ldap' or title == 'authn_db' |>
        ->
        icat::create_component { $component_info['name']:
          deployment_order => 100,
          setup_options    => "--binDir ${bin_dir}",
          templates        => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/icat-setup.properties.epp',
            'icat/icat.log4j.properties.epp',
            'icat/icat.properties.epp',
          ],
          template_params  => {
            'authn_plugins'         => join(get_all_authenticators($components), ' '),
            'authn_jndi_entries'    => construct_authenticator_jndi_entries($components),
            'crud_access_usernames' => join($component_info['crud_access_usernames'], ' '),
            'db_name'               => $db_name,
            'db_password'           => $db_password,
            'db_type'               => $db_type,
            'db_url'                => $db_url,
            'db_username'           => $db_username,
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
          },
          tmp_dir          => $tmp_dir,
          working_dir      => $working_dir,
          version          => $component_info['version'],
        }
      }
      default : {
        fail("Unrecognised component: ${component_info['name']}")
      }
    }
  }
  # lint:endignore
}
