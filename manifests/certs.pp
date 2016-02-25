# == Class: certs
#
# A class to manage the security certs for the app server.
#
# == Notes:
#
# This is basically what is shown in the "To Generate a Certificate by
# Using keytool" example at:
# https://glassfish.java.net/docs/4.0/security-guide.pdf
#
# More info:
# - https://docs.oracle.com/cd/E19798-01/821-1751/gczen/index.html
# - http://www.cloudera.com/documentation/enterprise/5-2-x/topics/cm_sg_create_key_trust.html
class icat::certs (
  $keystore_path    = undef,
  $cert_path        = undef,
  $cacerts_path     = undef,
  $jssecacerts_path = undef,
  $keytool_path     = undef,
  $hostname         = undef,
  $password         = undef,
) {
  $cert_commands = [
    "${keytool_path} -exportcert -keystore ${keystore_path} -file ${cert_path} -storepass ${password} -alias s1as",
    "cp ${cacerts_path} ${jssecacerts_path}",
    "${keytool_path} -storepasswd -keystore ${jssecacerts_path} -storepass changeit -new ${password}",
    "${keytool_path} -importcert -keystore ${jssecacerts_path} -file ${cert_path} -storepass ${password} -alias ${hostname} -noprompt" ,
  ]

  exec { 'setup_security_certificates':
    command => $cert_commands.join(' && '),
    unless  => "test -f ${jssecacerts_path}",
    path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }
}
