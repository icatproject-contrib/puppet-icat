# == Class: certs
#
# A class to manage the security certs for the app server.
#
# == Notes:
#
# There is some good information in the following links to do with creating certs with IP address aliases and similar, but ultimately setting the cert alias
# to be the same as the *hostname* and making sure the hostname is correct both from the point of view of the VM and it's clients
# was the way forward.
#
# http://stackoverflow.com/questions/8443081/how-are-ssl-certificate-server-names-resolved-can-i-add-alternative-names-using/8444863#8444863
# http://techcommunity.softwareag.com/widget/pwiki/-/wiki/Main/How+do+I+generate+keystores+and+certificates+for+command+central;jsessionid=300A03376881D287B585029EA05B7C90
# https://forge.fiware.org/plugins/mediawiki/wiki/fiware/index.php/Access_Control_-_Installation_and_Administration_Guide
#
# Note that a way to test if the cert stuff has worked is to run the following on the VM:
#
# ~/bin/icat-setup https://[hostname]:[https_port] db username [___] password [___]
#
# (TODO: make the above test an acceptance spec?)
class icat::certs (
  $keystore_path    = undef,
  $cert_path        = undef,
  $cacerts_path     = undef,
  $jssecacerts_path = undef,
  $keytool_path     = undef,
  $hostname         = undef,
) {
  $cert_commands = [
    "${keytool_path} -exportcert -keystore ${keystore_path} -file ${cert_path} -storepass changeit -alias s1as",
    "cp ${cacerts_path} ${jssecacerts_path}",
    "${keytool_path} -importcert -keystore ${jssecacerts_path} -file ${cert_path} -storepass changeit -alias ${hostname} -noprompt" ,
  ]

  notice($cert_commands.join(' && '))

  exec { 'setup_security_certificates':
    command => $cert_commands.join(' && '),
    unless  => "test -f ${jssecacerts_path}",
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }
}
