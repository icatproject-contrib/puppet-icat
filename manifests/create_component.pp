# == Define: icat::create_component
#
# Create an ICAT component.
define icat::create_component (
  $component_name  = $name,
  $group           = $icat::appserver_group,
  $maven_repos     = ['http://www.icatproject.org/mvn/repo'],
  $templates       = undef,
  $template_params = undef,
  $tmp_dir         = undef,
  $user            = $icat::appserver_user,
  $version         = undef,
) {
  validate_string($component_name)
  validate_string($group)
  validate_array($maven_repos)
  validate_array($templates)
  validate_hash($template_params)
  validate_absolute_path($tmp_dir)
  validate_string($user)
  validate_re(
    $version,
    '^(\d+\.\d+\.\d+(\-SNAPSHOT)?)|LATEST|RELEASE$',
    'Expected a version string of the form "[MAJOR].[MINOR].[PATCH]" with optional "-SNAPSHOT" suffix, or "LATEST" or "RELEASE".'
  )

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
  $extracted_path = "${tmp_dir}/${component_name}-${version}-distro"

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
    }
  }
}
