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
  $tmp_dir = undef,
) {
  $oracle_jdk_url         = 'http://download.oracle.com/otn-pub/java/jdk/7u79-b15/jdk-7u79-linux-x64.rpm'
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
  } ->
  package { 'jdk.x86_64' :
    ensure   => 'installed',
    provider => 'rpm',
    source   => $jdk_installer_path,
  }
}
