# == Class: icat
#
# This module manages an entire installation of ICAT.
class icat (
  $tmp_dir     = '/tmp',
  $manage_java = true,
) {
  validate_string($tmp_dir)
  validate_bool($manage_java)

  if $manage_java {
    class { 'icat::java':
      tmp_dir => $tmp_dir,
    }
  }
}
