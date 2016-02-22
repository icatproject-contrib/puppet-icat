# == Define: icat::create_component
#
# Create an ICAT component.
define icat::create_component (
  $component_name   = $name,
  $deployment_order = 100,
  $group            = $icat::appserver_group,
  $maven_repos      = ['http://www.icatproject.org/mvn/repo'],
  $patches          = {},
  $setup_options    = '',
  $templates        = undef,
  $template_params  = undef,
  $tmp_dir          = '/tmp',
  $user             = $icat::appserver_user,
  $version          = undef,
  $working_dir      = '/tmp',
) {
  validate_string($component_name)
  validate_integer($deployment_order)
  validate_string($group)
  validate_array($maven_repos)
  validate_hash($patches)
  validate_string($setup_options)
  validate_array($templates)
  validate_hash($template_params)
  validate_absolute_path($tmp_dir)
  validate_string($user)
  validate_re(
    $version,
    '^(\d+\.\d+\.\d+(\-SNAPSHOT)?)|LATEST|RELEASE$',
    'Expected a version string of the form "[MAJOR].[MINOR].[PATCH]" with optional "-SNAPSHOT" suffix, or "LATEST" or "RELEASE".'
  )
  validate_absolute_path($working_dir)

  # TODO: accept optional inner_comp_name as parameter.  Only if not set use the following.

  # Account for non-standard inner directory name of the newest topcat version.
  if $component_name == 'topcat' {
    $inner_comp_name  = 'topcatv2'
  }
  # Account for case difference between inner directory name and outer component name
  # in the old topcat version.
  else {
    $inner_comp_name  = $component_name.downcase
  }

  $zip_path = "${tmp_dir}/${component_name}-${version}-distro.zip"
  $extracted_path = "${working_dir}/${component_name}-${version}-distro"

  realize( Class['maven::maven'] )
  realize( Package['unzip'] )

  maven { $zip_path:
    groupid    => 'org.icatproject',
    artifactid => $component_name,
    version    => $version,
    classifier => 'distro',
    packaging  => 'zip',
    repos      => $maven_repos,
    user       => $user,
    group      => $group,
    require    => Class['maven::maven'],
  } ~>
  exec { "extract_${component_name}":
    command => "unzip -q -d ${extracted_path} ${zip_path}",
    path    => '/usr/bin/',
    unless  => "test -d ${extracted_path}",
    require => [Package['unzip']],
  } ->
  file { $extracted_path :
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => '0600',
    recurse => true,
  }

  $templates.each |String $template_path| {
    $properties_file_path = construct_icat_comp_prop_file_path(
      $extracted_path, $inner_comp_name, $template_path
    )

    file { $properties_file_path:
      ensure  => 'present',
      content => epp($template_path, $template_params),
      owner   => $user,
      group   => $group,
      mode    => '0600',
      require => File[$extracted_path],
      notify  => Exec["configure_${name}_setup_script"],
    }
  }

  $patches.each |String $original_rel_path, String $patch_path| {
    $original_path = "${extracted_path}/${inner_comp_name}/${original_rel_path}"

    validate_string($patch_path)
    validate_string($original_path)

    # To enable us to use the "puppet:///path/to/file" URI syntax when using this
    # module, we actually have to first create a local version of the patch on the
    # node.
    file { "${original_path}.patch":
      source  => $patch_path,
      require => File[$extracted_path],
    }
    ~>
    exec { "apply_${component_name}_${original_rel_path}_patch":
      command => "patch ${original_path} ${original_path}.patch",
      path    => '/usr/bin/',
      # Subtle, but this is the only true test as to whether the patch has already been applied,
      # i.e., if the patch can be reversed then there's no need to apply it a second time.
      unless  => "patch -R --dry-run ${original_path} ${original_path}.patch",
      notify  => Exec["configure_${name}_setup_script"],
    }
  }

  realize( Package['python-suds'] )

  # TODO: The following resources DO NOT necessarily wait for the the icat domain service
  #       to be running before applying themselves.  I have manually stopped the service,
  #       re-run Puppet and seen the following resource fall over, *then* seen the icat
  #       service be started by Puppet.  I think there may be example code of how to fix
  #       this in the glassfish module on GitHub, else "puppet containing" is probably the
  #       term to Google to investigate this further.

  exec { "configure_${component_name}_setup_script":
    command     => "python setup ${setup_options} CONFIGURE",
    path        => '/usr/bin/',
    cwd         => "${extracted_path}/${inner_comp_name}",
    user        => $user,
    group       => $group,
    refreshonly => true,
    require     => [Package['python-suds']],
  } ~>
  exec { "run_${component_name}_setup_script":
    command     => "python setup ${setup_options} INSTALL",
    path        => '/usr/bin/',
    cwd         => "${extracted_path}/${inner_comp_name}",
    user        => $user,
    group       => $group,
    refreshonly => true,
    require     => [Exec["configure_${component_name}_setup_script"]],
  }
  ~>
  # lint:ignore:ensure_first_param
  set { "applications.application.${component_name}-${version}.deployment-order":
    asadminuser => $icat::appserver_admin_user,
    ensure      => 'present',
    user        => $user,
    value       => $deployment_order,
  }
  # lint:endignore
}
