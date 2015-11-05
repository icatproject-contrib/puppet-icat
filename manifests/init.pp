# == Class: icat
#
# This module manages an entire installation of ICAT.
class icat (
  $tmp_dir = '/tmp'
) {
  file { $tmp_dir:
    ensure => 'directory',
  }
}
