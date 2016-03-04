# == Class: java
#
# A class that will manage Java if the functionality has been enabled in the
# ICAT class.
#
# This is necessary since a requirement of ICAT is that an official Oracle JDK
# is used.  There is an existing Puppetlabs module that is really nice but we
# cannot use it since it wont give us the Oracle JDK on CentOS.  A similar
# situation exists for the `manage_java` functionality of the glassfish module.
#
# We are therefore left with the problem of navigating Oracle's licence
# acceptance pages in an automated fashion, which unforunately is non-trivial.
#
# See http://stackoverflow.com/questions/10268583/ for more info.

class icat::java (
  $group        = undef,
  $jdk_rpm_path = undef,
  $tmp_dir      = undef,
  $user         = undef,
) {
  if $jdk_rpm_path != undef {
    $jdk_rpm_basename = basename($jdk_rpm_path)
    $tmp_jdk_rpm = "${tmp_dir}/${jdk_rpm_basename}"
    file { $tmp_jdk_rpm:
      ensure => 'file',
      source => $jdk_rpm_path,
      owner  => $user,
      group  => $group,
    }
    ->
    package { 'jdk1.8.0_74-2000:1.8.0_74-fcs.x86_64' :
      ensure   => 'installed',
      provider => 'rpm',
      source   => $tmp_jdk_rpm,
    }
  }
  else {
    $oracle_jdk_url         = 'http://download.oracle.com/otn-pub/java/jdk/8u74-b02/jdk-8u74-linux-x64.rpm'
    $jdk_installer_filename = basename($oracle_jdk_url)
    $jdk_installer_path     = "${tmp_dir}/${jdk_installer_filename}"
    $accept_licence_flags   = "--no-cookies --header 'Cookie: oraclelicense=accept-securebackup-cookie'"

    realize( Package['wget'] )
    realize( File[$tmp_dir] )

    # Download the JDK, but only if we don't have it already.
    exec { 'download_jdk':
      command => "wget -v --no-check-certificate ${accept_licence_flags} ${oracle_jdk_url} -O ${jdk_installer_path}",
      path    => '/usr/bin/',
      creates => $jdk_installer_path,
      require => [
        Package['wget'],
        File[$tmp_dir],
      ]
    }
    ->
    package { 'jdk1.8.0_74-2000:1.8.0_74-fcs.x86_64' :
      ensure   => 'installed',
      provider => 'rpm',
      source   => $jdk_installer_path,
    }
  }
}
