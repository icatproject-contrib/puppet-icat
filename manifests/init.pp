# == Class: icat
#
# This module manages an entire installation of ICAT.
class icat (
  $appserver_admin_master_password = 'adminadmin',
  $appserver_admin_password        = 'changeit',
  $appserver_admin_port            = 4848,
  $appserver_install_dir           = '/usr/local/',
  $appserver_group                 = 'root',
  $appserver_user                  = 'root',

  $components                      = [],

  $db_name                         = 'icat',
  $db_password                     = 'password',
  $db_type                         = 'mysql',
  $db_url                          = 'jdbc:mysql://localhost:3306/icat',
  $db_username                     = 'username',

  $manage_java                     = true,

  $tmp_dir                         = '/tmp',
  $working_dir                     = '/tmp',
) {
  validate_string($appserver_admin_master_password)
  validate_string($appserver_admin_password)
  validate_integer($appserver_admin_port)
  validate_string($appserver_group)
  validate_string($appserver_user)

  validate_array($components)

  validate_string($db_name)
  validate_string($db_password)
  validate_string($db_type)
  validate_string($db_url)
  validate_string($db_username)

  validate_bool($manage_java)

  validate_string($tmp_dir)
  validate_string($working_dir)

  if $manage_java {
    class { 'icat::java':
      tmp_dir => $tmp_dir,
      before  => Class['icat::appserver'],
    }
  }

  class { 'icat::appserver':
    tmp_dir               => $tmp_dir,
    user                  => $appserver_user,
    group                 => $appserver_group,
    admin_password        => $appserver_admin_password,
    admin_master_password => $appserver_admin_master_password,
    db_type               => $db_type,
  }

  # lint:ignore:variable_scope
  $components.each |Integer $index, Hash $component_info| {
    validate_hash($component_info)

    unless has_key($component_info, 'name')    { fail('Component name required.') }
    unless has_key($component_info, 'version') { fail('Component version required.') }

    case $component_info['name'] {
      'authn_db' : {
        icat::create_component { $component_info['name']:
          patches         => {
            # See: https://docs.puppetlabs.com/guides/file_serving.html#serving-module-files
            'setup_utils.py' => 'puppet:///modules/icat/patches/authn_db_setup_utils.patch',
          },
          templates       => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/authn_db-setup.properties.epp',
            'icat/authn_db.properties.epp',
          ],
          template_params => {
            'db_name'               => $db_name,
            'db_password'           => $db_password,
            'db_type'               => $db_type,
            'db_url'                => $db_url,
            'db_username'           => $db_username,
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
          },
          tmp_dir         => $tmp_dir,
          working_dir     => $working_dir,
          version         => $component_info['version'],
        }
      }
      'authn_ldap' : {
        unless has_key($component_info, 'provider_url')       { fail('LDAP provider URL required.') }
        unless has_key($component_info, 'security_principal') { fail('LDAP security principal required.') }

        icat::create_component { $component_info['name']:
          templates       => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/authn_ldap-setup.properties.epp',
            'icat/authn_ldap.properties.epp',
          ],
          template_params => {
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
            'provider_url'          => $component_info['provider_url'],
            'security_principal'    => $component_info['security_principal'],
          },
          tmp_dir         => $tmp_dir,
          working_dir     => $working_dir,
          version         => $component_info['version'],
        }
      }
      'authn_simple' : {
        unless has_key($component_info, 'credentials') { fail('Simple credentials required.') }

        icat::create_component { $component_info['name']:
          templates       => [
            # See: https://docs.puppetlabs.com/puppet/latest/reference/lang_template.html#referencing-files
            'icat/authn_simple-setup.properties.epp',
            'icat/authn_simple.properties.epp',
          ],
          template_params => {
            'credentials'           => $component_info['credentials'],
            'glassfish_install_dir' => "${appserver_install_dir}glassfish-4.0/",
            'glassfish_admin_port'  => $appserver_admin_port,
          },
          tmp_dir         => $tmp_dir,
          working_dir     => $working_dir,
          version         => $component_info['version'],
        }
      }
      default : {
        fail("Unrecognised component: ${component_info['name']}")
      }
    }
  }
  # lint:endignore
}
