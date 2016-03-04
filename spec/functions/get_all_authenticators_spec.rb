require 'spec_helper'

test_components = [{
    'name'    => 'authn.db',
    'version' => '1.1.2',
  }, {
    'name'               => 'authn.ldap',
    'version'            => '1.1.0',
    'provider_url'       => 'ldap://data.sns.gov:389',
    'security_principal' => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
  }, {
    'name'        => 'authn.simple',
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

describe 'get_all_authenticators' do
  it { should run.with_params(test_components)
    .and_return(['db', 'ldap', 'simple']) }
  it { should run.with_params('wrong', 'number', 'of', 'arguments').and_raise_error(Puppet::ParseError) }
end
