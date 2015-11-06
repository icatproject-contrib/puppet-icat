# == Class: java
#
# A class to manage Java, if the functionality has been enabled in the icat class.
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
