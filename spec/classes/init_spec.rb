require 'spec_helper'

describe 'icat' do
  let :pre_condition do
    <<-EOS
    @class { 'maven::maven': }
    @package { 'wget': ensure => installed }
    @file { '/tmp': ensure => 'directory' }
    @package { 'python-suds': ensure => installed }
    EOS
  end

  let :facts do
    { :osfamily => 'RedHat' }
  end

  context 'basic' do

    let :params do
      {
        'appserver_admin_password'        => 'p4ssw0rd',
        'appserver_admin_master_password' => 'master_p4ssw0rd',
      }
    end

    describe 'with default/reasonable param values' do
      it 'should compile' do
        should compile.with_all_deps()

        should create_class('icat')
      end

      it 'should create icat::appserver which should use icat::java' do
        should contain_class('icat::appserver').that_requires('Class[icat::java]')
      end
    end

    describe 'set to not manage java' do
      let :params do
        {'manage_java' => 'false'}
      end

      it 'should not create icat::java class' do
        should contain_class('icat::java') == 'false'
      end
    end
  end

  let (:default_component_params) do
    {
      'appserver_admin_master_password' => 'adminadmin',
      'appserver_admin_password'        => 'changeit',
      'appserver_admin_port'            => 4848,
      'appserver_install_dir'           => '/usr/local/',
      'appserver_group'                 => '',
      'appserver_user'                  => 'root',

      'db_name'                         => 'icat',
      'db_password'                     => 'password',
      'db_type'                         => 'mysql',
      'db_url'                          => 'jdbc:mysql://localhost:3306/icat',
      'db_username'                     => 'username',

      'manage_java'                     => true,

      'tmp_dir'                         => '/tmp',
      'working_dir'                     => '/tmp',
    }
  end

  context 'authn_db component selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
          'name'    => 'authn_db',
          'version' => '1.1.2',
        }]
      )
    end

    it do
      should contain_icat__create_component('authn_db').with({
        'component_name'  => 'authn_db',
        'patches'         => {
          'setup_utils.py' => 'puppet:///modules/icat/patches/authn_db_setup_utils.patch',
        },
        'templates'       => [
          'icat/authn_db-setup.properties.epp',
          'icat/authn_db.properties.epp',
        ],
        'template_params' => {
          'db_name'               => 'icat',
          'db_password'           => 'password',
          'db_type'               => 'mysql',
          'db_url'                => 'jdbc:mysql://localhost:3306/icat',
          'db_username'           => 'username',
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
        },
        'tmp_dir'         => '/tmp',
        'working_dir'     => '/tmp',
        'version'         => '1.1.2',
      })
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn_db-1.1.2-distro/authn_db/authn_db-setup.properties').with_content(
        "# Driver and connection properties for the MySQL database.\n" \
        "driver=com.mysql.jdbc.jdbc2.optional.MysqlDataSource\n" \
        "dbProperties=url=\"'\"jdbc:mysql://localhost:3306/icat\"'\":user=username:password=password:databaseName=icat\n" \
        "\n" \
        "# Must contain \"glassfish/domains\"\n" \
        "glassfish=/usr/local/glassfish-4.0/\n" \
        "\n" \
        "# Port for glassfish admin calls (normally 4848)\n" \
        "port=4848\n"
      )
      should contain_file('/tmp/authn_db-1.1.2-distro/authn_db/authn_db.properties').with_content(
        "# Real comments in this file are marked with '#' whereas commented out lines\n" \
        "# are marked with '!'\n" \
        "\n" \
        "# If access to the DB authentication should only be allowed from certain\n" \
        "# IP addresses then provide a space separated list of allowed values. These \n" \
        "# take the form of an IPV4 or IPV6 address followed by the number of bits \n" \
        "# (starting from the most significant) to consider.\n" \
        "!ip = 130.246.0.0/16   172.16.68.0/24\n" \
        "\n" \
        "# The mechanism label to appear before the user name. This may be omitted.\n" \
        "!mechanism = db"
      )
    end
  end

  context 'authn_ldap component selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
          'name'               => 'authn_ldap',
          'version'            => '1.1.0',
          'provider_url'       => 'ldap://data.sns.gov:389',
          'security_principal' => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
        }]
      )
    end

    it do
      should contain_icat__create_component('authn_ldap').with({
        'component_name'  => 'authn_ldap',
        'patches'         => {},
        'templates'       => [
          'icat/authn_ldap-setup.properties.epp',
          'icat/authn_ldap.properties.epp',
        ],
        'template_params' => {
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
          'provider_url'          => 'ldap://data.sns.gov:389',
          'security_principal'    => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
        },
        'tmp_dir'         => '/tmp',
        'working_dir'     => '/tmp',
        'version'         => '1.1.0',
      })
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn_ldap-1.1.0-distro/authn_ldap/authn_ldap-setup.properties').with_content(
        "# Must contain \"glassfish/domains\"\n" \
        "glassfish=/usr/local/glassfish-4.0/\n" \
        "\n" \
        "# Port for glassfish admin calls (normally 4848)\n" \
        "port=4848\n"
      )
      should contain_file('/tmp/authn_ldap-1.1.0-distro/authn_ldap/authn_ldap.properties').with_content(
        "# Real comments in this file are marked with '#' whereas commented out lines\n" \
        "# are marked with '!'\n" \
        "\n" \
        "# The following are needed for ldap authentication. The % character in the \n" \
        "# security_principal will be replaced by the specified user name. If you \n" \
        "# just use % then the user must enter a complete security_principal as his \n" \
        "# user name.\n" \
        "provider_url ldap://data.sns.gov:389\n" \
        "security_principal uid=%,ou=Users,dc=sns,dc=ornl,dc=gov\n" \
        "\n" \
        "# The following may be provided to override or add to the default context\n" \
        "!context.props = java.naming.factory.initial java.naming.security.authentication\n" \
        "!context.props.java.naming.factory.initial = com.sun.jndi.ldap.LdapCtxFactory\n" \
        "!context.props.java.naming.security.authentication = simple\n" \
        "\n" \
        "# To map the provided name to something derived from an LDAP query. The % \n" \
        "# in the ldap filter will be replaced by the provided user name.\n" \
        "!ldap.base = DC=fed,DC=cclrc,DC=ac,DC=uk\n" \
        "!ldap.filter = (&(CN=%)(objectclass=user))\n" \
        "!ldap.attribute = name\n" \
        "\n" \
        "# To force the case to be all lower\n" \
        "case = lower\n" \
        "\n" \
        "# If access to the ldap authentication should only be allowed from certain \n" \
        "# IP addresses then provide a space separated list of allowed values. These \n" \
        "# take the form of an IPV4 or IPV6 address followed by the number of bits \n" \
        "# (starting from the most significant) to consider.\n" \
        "!ip   130.246.0.0/16   172.16.68.0/24\n" \
        "\n" \
        "# The mechanism label to appear before the user name. This may be omitted.\n" \
        "!mechanism ldap\n"
      )
    end
  end

  context 'authn_simple component selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
          'name'        => 'authn_simple',
          'version'     => '1.0.1',
          'credentials' => {
            'user_a' => 'password_a',
            'user_b' => 'password_b',
          },
        }]
      )
    end

    it do
      should contain_icat__create_component('authn_simple').with({
        'component_name'  => 'authn_simple',
        'patches'         => {},
        'templates'       => [
          'icat/authn_simple-setup.properties.epp',
          'icat/authn_simple.properties.epp',
        ],
        'template_params' => {
          'credentials' => {
            'user_a' => 'password_a',
            'user_b' => 'password_b',
          },
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
        },
        'tmp_dir'         => '/tmp',
        'working_dir'     => '/tmp',
        'version'         => '1.0.1',
      })
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn_simple-1.0.1-distro/authn_simple/authn_simple-setup.properties').with_content(
        "# Must contain \"glassfish/domains\"\n" \
        "glassfish=/usr/local/glassfish-4.0/\n" \
        "\n" \
        "# Port for glassfish admin calls (normally 4848)\n" \
        "port=4848\n"
      )
      should contain_file('/tmp/authn_simple-1.0.1-distro/authn_simple/authn_simple.properties').with_content(
        "# Real comments in this file are marked with '#' whereas commented out lines\n" \
        "# are marked with '!'\n" \
        "\n" \
        "# Space separated list of user names that this plugin authenticates.\n" \
        "user.list = user_a user_b\n" \
        "\n" \
        "# Password for each user.  This may either be a clear text password or\n" \
        "# a cryptographic hash of a password.\n" \
        "#\n" \
        "# A password hash must start with a '$' character and be in the same\n" \
        "# form as found in the shadow(5) password file.  It may be created\n" \
        "# using the mkpasswd(1) utility on Debian systems or grub-crypt on \n" \
        "# Red Hat derived systems or the python crypt module.  The supported hash\n" \
        "# algorithms are MD5, SHA-256, and SHA-512.\n" \
        "#\n" \
        "# A clear text password must not start with a '$' character.\n" \
        "user.user_a.password = password_a\n" \
        "user.user_b.password = password_b\n" \
        "\n" \
        "# If access to the simple authentication should only be allowed from certain \n" \
        "# IP addresses then provide a space separated list of allowed values. These \n" \
        "# take the form of an IPV4 or IPV6 address followed by the number of bits \n" \
        "# (starting from the most significant) to consider.\n" \
        "!ip = 130.246.0.0/16   172.16.68.0/24\n" \
        "\n" \
        "# The mechanism label to appear before the user name. This may be omitted.\n" \
        "!mechanism = simple\n"
      )
    end
  end

  context 'unrecognised component name' do
    let(:params) do
      {
        'components' => [{
          'name'    => 'does_not_exist',
          'version' => '1.1.2',
        }],
      }
    end

    it { is_expected.to compile.and_raise_error(/Unrecognised component: does_not_exist/) }
  end
end
