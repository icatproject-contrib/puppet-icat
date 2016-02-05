require 'spec_helper'

test_components = [{
    'name'    => 'authn_db',
    'version' => '1.1.2',
  }, {
    'name'               => 'authn_ldap',
    'version'            => '1.1.0',
    'provider_url'       => 'ldap://data.sns.gov:389',
    'security_principal' => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
  }, {
    'name'        => 'authn_simple',
    'version'     => '1.0.1',
    'credentials' => {
      'user_a' => 'password_a',
      'user_b' => 'password_b',
    },
  }, {
    'name'        => 'icat.server',
    'version'     => '4.5.0',
  }
]

expected_result = [
  "authn.db.jndi java:global/authn_db-1.1.2/DB_Authenticator",
  "authn.ldap.jndi java:global/authn_ldap-1.1.0/LDAP_Authenticator",
  "authn.simple.jndi java:global/authn_simple-1.0.1/SIMPLE_Authenticator",
]

describe 'construct_authenticator_jndi_entries' do
  it { should run.with_params(test_components).and_return(expected_result) }
  it { should run.with_params('wrong', 'number', 'of', 'arguments').and_raise_error(Puppet::ParseError) }
end
