# == Define: icat::create_component
#
# Create an ICAT component.
define icat::create_component (
  $component_name = $name,
  $maven_repos    = ['http://www.icatproject.org/mvn/repo'],
  $templates      = undef,
  $tmp_dir        = undef,
  $version        = undef,
) {
  validate_string($component_name)
  validate_array($maven_repos)
  validate_array($templates)
  validate_absolute_path($tmp_dir)
  validate_re(
    $version,
    '^\d+\.\d+\.\d+(\-SNAPSHOT)?$',
    'Expected a version string of the form "[MAJOR].[MINOR].[PATCH]" with optional "-SNAPSHOT" suffix.'
  )
}
