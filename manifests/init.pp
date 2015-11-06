# == Class: icat
#
# This module manages an entire installation of ICAT.
class icat (
  $tmp_dir         = '/tmp',
  $manage_java     = true,
  $appserver_user  = 'root',
  $appserver_group = 'root',
) {
  validate_string($tmp_dir)
  validate_bool($manage_java)

  validate_string($appserver_user)
  validate_string($appserver_group)

  if $manage_java {
    class { 'icat::java':
      tmp_dir => $tmp_dir,
      before  => Class['icat::appserver'],
    }
  }

  class { 'icat::appserver':
    tmp_dir => $tmp_dir,
    user    => $appserver_user,
    group   => $appserver_group,
  }
}
