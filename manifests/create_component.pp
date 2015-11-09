# == Define: icat::create_component
#
# Create an ICAT component.
define icat::create_component (
  $component_name = $name,
  $group          = $icat::appserver_group,
  $maven_repos    = ['http://www.icatproject.org/mvn/repo'],
  $templates      = undef,
  $tmp_dir        = undef,
  $user           = $icat::appserver_user,
  $version        = undef,
) {
  validate_string($component_name)
  validate_array($maven_repos)
  validate_array($templates)
  validate_absolute_path($tmp_dir)
  validate_re(
    $version,
    '^(\d+\.\d+\.\d+(\-SNAPSHOT)?)|LATEST|RELEASE$',
    'Expected a version string of the form "[MAJOR].[MINOR].[PATCH]" with optional "-SNAPSHOT" suffix, or "LATEST" or "RELEASE".'
  )

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
  }
}
