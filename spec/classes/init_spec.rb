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
      'appserver_admin_passfile'        => '/tmp/asadmin.pass',
      'appserver_admin_password'        => 'changeit',
      'appserver_admin_user'            => 'admin',
      'appserver_install_dir'           => '/usr/local/',
      'appserver_group'                 => '',
      'appserver_portbase'              => 4800,
      'appserver_user'                  => 'root',

      'bin_dir'                         => '/usr/local/bin',

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

  let (:oracle_alternative_component_params) do
    {
      'appserver_admin_master_password' => 'adminadmin',
      'appserver_admin_passfile'        => '/tmp/asadmin.pass',
      'appserver_admin_password'        => 'changeit',
      'appserver_admin_user'            => 'admin',
      'appserver_install_dir'           => '/usr/local/',
      'appserver_group'                 => '',
      'appserver_portbase'              => 4800,
      'appserver_user'                  => 'root',

      'bin_dir'                         => '/usr/local/bin',

      'connector_jar_path'              => 'puppet:///modules/icat/dummy_connector/ojdbc6.jar',

      'db_name'                         => 'icat',
      'db_password'                     => 'password',
      'db_type'                         => 'oracle',
      'db_url'                          => 'jdbc:oracle:thin:@//localhost:1521/scdevl',
      'db_username'                     => 'username',

      'manage_java'                     => true,

      'tmp_dir'                         => '/tmp',
      'working_dir'                     => '/tmp',
    }
  end

  context 'authn.db component selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
          'name'    => 'authn.db',
          'version' => '1.2.0',
        }]
      )
    end

    it do
      should contain_icat__create_component('authn.db').with({
        'component_name'   => 'authn.db',
        'deployment_order' => 80,
        'templates'        => [
          'icat/authn_db-setup.properties.epp',
          'icat/authn_db.properties.epp',
        ],
        'template_params'  => {
          'db_name'               => 'icat',
          'db_password'           => 'password',
          'db_type'               => 'mysql',
          'db_url'                => 'jdbc:mysql://localhost:3306/icat',
          'db_username'           => 'username',
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
        },
        'tmp_dir'          => '/tmp',
        'working_dir'      => '/tmp',
        'version'          => '1.2.0',
      }).that_requires('icat::appserver')
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn.db-1.2.0-distro/authn.db/authn_db-setup.properties').with_content(
        "secure         = true\n" \
        "container      = glassfish\n" \
        "home           = /usr/local/glassfish-4.0/\n" \
        "port           = 4848\n" \
        "\n" \
        "db.vendor      = mysql\n" \
        "\n" \
        "\n" \
        "db.driver      = com.mysql.jdbc.jdbc2.optional.MysqlDataSource\n" \
        "\n" \
        "\n" \
        "db.url         = jdbc:mysql://localhost:3306/icat\n" \
        "db.username    = username\n" \
        "db.password    = password\n"
      )
      should contain_file('/tmp/authn.db-1.2.0-distro/authn.db/authn_db.properties').with_content(
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

  context 'authn.db component selected with oracle' do
    let(:params) do
      oracle_alternative_component_params.merge(
        'components' => [{
          'name'    => 'authn.db',
          'version' => '1.2.0',
        }]
      )
    end
    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn.db-1.2.0-distro/authn.db/authn_db-setup.properties').with_content(
        "secure         = true\n" \
        "container      = glassfish\n" \
        "home           = /usr/local/glassfish-4.0/\n" \
        "port           = 4848\n" \
        "\n" \
        "db.vendor      = oracle\n" \
        "\n" \
        "\n" \
        "db.driver      = oracle.jdbc.pool.OracleDataSource\n" \
        "\n" \
        "\n" \
        "db.url         = jdbc:oracle:thin:@//localhost:1521/scdevl\n" \
        "db.username    = username\n" \
        "db.password    = password\n"
      )
    end
  end

  context 'authn.ldap component selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
          'name'               => 'authn.ldap',
          'version'            => '1.2.0',
          'provider_url'       => 'ldap://data.sns.gov:389',
          'security_principal' => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
        }]
      )
    end

    it do
      should contain_icat__create_component('authn.ldap').with({
        'component_name'   => 'authn.ldap',
        'deployment_order' => 80,
        'patches'          => {},
        'templates'        => [
          'icat/authn_ldap-setup.properties.epp',
          'icat/authn_ldap.properties.epp',
        ],
        'template_params'  => {
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
          'provider_url'          => 'ldap://data.sns.gov:389',
          'security_principal'    => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
        },
        'tmp_dir'          => '/tmp',
        'working_dir'      => '/tmp',
        'version'          => '1.2.0',
      }).that_requires('icat::appserver')
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn.ldap-1.2.0-distro/authn.ldap/authn_ldap-setup.properties').with_content(
        "secure         = true\n" \
        "container      = glassfish\n" \
        "home           = /usr/local/glassfish-4.0/\n" \
        "port           = 4848\n"
      )
      should contain_file('/tmp/authn.ldap-1.2.0-distro/authn.ldap/authn_ldap.properties').with_content(
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

  context 'authn.simple component selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
          'name'        => 'authn.simple',
          'version'     => '1.1.0',
          'credentials' => {
            'user_a' => 'password_a',
            'user_b' => 'password_b',
          },
        }]
      )
    end

    it do
      should contain_icat__create_component('authn.simple').with({
        'component_name'   => 'authn.simple',
        'deployment_order' => 80,
        'patches'          => {},
        'templates'        => [
          'icat/authn_simple-setup.properties.epp',
          'icat/authn_simple.properties.epp',
        ],
        'template_params'  => {
          'credentials' => {
            'user_a' => 'password_a',
            'user_b' => 'password_b',
          },
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
        },
        'tmp_dir'          => '/tmp',
        'working_dir'      => '/tmp',
        'version'          => '1.1.0',
      }).that_requires('icat::appserver')
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/authn.simple-1.1.0-distro/authn.simple/authn_simple-setup.properties').with_content(
        "secure         = true\n" \
        "container      = glassfish\n" \
        "home           = /usr/local/glassfish-4.0/\n" \
        "port           = 4848\n"
      )
      should contain_file('/tmp/authn.simple-1.1.0-distro/authn.simple/authn_simple.properties').with_content(
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

  context 'icat.server and three authenticator components selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
            'name'    => 'authn.db',
            'version' => '1.2.0',
          }, {
            'name'               => 'authn.ldap',
            'version'            => '1.2.0',
            'provider_url'       => 'ldap://data.sns.gov:389',
            'security_principal' => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
          }, {
            'name'        => 'authn.simple',
            'version'     => '1.1.0',
            'credentials' => {
              'user_a' => 'password_a',
              'user_b' => 'password_b',
            },
          }, {
            'name'                  => 'icat.server',
            'version'               => '4.6.0',
            'crud_access_usernames' => ['user_a', 'user_b'],
          }
        ]
      )
    end

    it do
      should contain_icat__create_component('icat.server').with({
        'component_name'   => 'icat.server',
        'deployment_order' => 100,
        'patches'          => {},
        'setup_options'    => '--binDir /usr/local/bin',
        'templates'        => [
          'icat/icat-setup.properties.epp',
          'icat/icat.log4j.properties.epp',
          'icat/icat.properties.epp',
        ],
        'template_params'  => {
          'authn_plugins'         => "db ldap simple",
          'authn_jndi_entries'    => [
            "authn.db.jndi java:global/authn.db-1.2.0/DB_Authenticator",
            "authn.ldap.jndi java:global/authn.ldap-1.2.0/LDAP_Authenticator",
            "authn.simple.jndi java:global/authn.simple-1.1.0/SIMPLE_Authenticator",
            ],
          'crud_access_usernames' => "user_a user_b",
          'db_name'               => 'icat',
          'db_password'           => 'password',
          'db_type'               => 'mysql',
          'db_url'                => 'jdbc:mysql://localhost:3306/icat',
          'db_username'           => 'username',
          'glassfish_install_dir' => '/usr/local/glassfish-4.0/',
          'glassfish_admin_port'  => 4848,
        },
        'tmp_dir'          => '/tmp',
        'working_dir'      => '/tmp',
        'version'          => '4.6.0',
      }).that_requires('icat::appserver')
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/icat.server-4.6.0-distro/icat.server/icat-setup.properties').with_content(
        "secure         = true\n" \
        "container      = glassfish\n" \
        "home           = /usr/local/glassfish-4.0/\n" \
        "port           = 4848\n" \
        "\n" \
        "db.vendor      = mysql\n" \
        "\n" \
        "\n" \
        "db.driver      = com.mysql.jdbc.jdbc2.optional.MysqlDataSource\n" \
        "\n" \
        "\n" \
        "db.url         = jdbc:mysql://localhost:3306/icat\n" \
        "db.username    = username\n" \
        "db.password    = password\n"
      )
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/icat.server-4.6.0-distro/icat.server/icat.log4j.properties').with_content(
        "log4j.rootLogger=DEBUG, logfile\n" \
        "\n" \
        "log4j.appender.logfile=org.apache.log4j.DailyRollingFileAppender\n" \
        "log4j.appender.logfile.Threshold=TRACE\n" \
        "log4j.appender.logfile.file=../logs/icat.log\n" \
        "log4j.appender.logfile.layout=org.apache.log4j.PatternLayout\n" \
        "log4j.appender.logfile.layout.ConversionPattern=%d [%t] %-5p %C{1} - %m%n\n"
      )
    end

    it 'should generate the templated properties files correctly' do
      should contain_file('/tmp/icat.server-4.6.0-distro/icat.server/icat.properties').with_content(
        "# Real comments in this file are marked with '#' whereas commented out lines\n" \
        "# are marked with '!'\n" \
        "\n" \
        "# The lifetime of a session\n" \
        "lifetimeMinutes 120\n" \
        "\n" \
        "# Provide CRUD access to authz tables\n" \
        "rootUserNames user_a user_b\n" \
        "\n" \
        "# Restrict total number of entities to return in a search call\n" \
        "maxEntities 1000\n" \
        "\n" \
        "# Maximum ids in a list - this must not exceed 1000 for Oracle\n" \
        "maxIdsInQuery 500\n" \
        "\n" \
        "# Size of cache to be used when importing data into ICAT\n" \
        "importCacheSize 50\n" \
        "\n" \
        "# Size of cache to be used when exporting data from ICAT\n" \
        "exportCacheSize 50\n" \
        "\n" \
        "# Desired authentication plugin mnemonics\n" \
        "authn.list db ldap simple\n" \
        "\n" \
        "# JNDI for each plugin\n" \
        "authn.db.jndi java:global/authn.db-1.2.0/DB_Authenticator\n" \
        "authn.ldap.jndi java:global/authn.ldap-1.2.0/LDAP_Authenticator\n" \
        "authn.simple.jndi java:global/authn.simple-1.1.0/SIMPLE_Authenticator\n" \
        "\n" \
        "!log4j.properties icat.log4j.properties\n" \
        "\n" \
        "# Notification setup\n" \
        "notification.list = Dataset Datafile\n" \
        "notification.Dataset = CU\n" \
        "notification.Datafile = CU\n" \
        "\n" \
        "# Call logging setup\n" \
        "log.list = file table\n" \
        "log.file = S\n" \
        "log.table = S\n" \
        "\n" \
        "# Lucene\n" \
        "!lucene.directory = ../data/icat/lucene\n" \
        "lucene.commitSeconds = 1\n" \
        "lucene.commitCount = 1000\n"
      )
    end

    it 'should make sure the icat.server module depends on all three authn modules' do
      should contain_icat__create_component('icat.server')
        .that_requires('ICAT::Create_Component[authn.simple]')
      should contain_icat__create_component('icat.server')
        .that_requires('ICAT::Create_Component[authn.ldap]')
      should contain_icat__create_component('icat.server')
        .that_requires('ICAT::Create_Component[authn.db]')
    end
  end

  context 'icat.server and only two authenticator components selected' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
            'name'    => 'authn.db',
            'version' => '1.2.0',
          }, {
            'name'               => 'authn.ldap',
            'version'            => '1.2.0',
            'provider_url'       => 'ldap://data.sns.gov:389',
            'security_principal' => 'uid=%,ou=Users,dc=sns,dc=ornl,dc=gov',
          }, {
            'name'                  => 'icat.server',
            'version'               => '4.6.0',
            'crud_access_usernames' => ['user_a', 'user_b'],
          }
        ]
      )
    end

    it 'should make sure the icat.server module depends on those two authn modules' do
      should contain_icat__create_component('icat.server')
        .that_requires('ICAT::Create_Component[authn.db]')
      should contain_icat__create_component('icat.server')
        .that_requires('ICAT::Create_Component[authn.ldap]')
    end
  end

  context 'out-of-date icat.server and an authenticator component' do
    let(:params) do
      default_component_params.merge(
        'components' => [{
            'name'        => 'authn.simple',
            'version'     => '1.1.0',
            'credentials' => {
              'user_a' => 'password_a',
              'user_b' => 'password_b',
            },
          }, {
            'name'                  => 'icat.server',
            'version'               => '4.5.0',
            'crud_access_usernames' => ['user_a', 'user_b'],
          }
        ]
      )
    end

    it do
      expect {
        should compile
      }.to raise_error(/Versions of icat.server/)
    end

  end

  context 'unrecognised component name' do
    let(:params) do
      {
        'components' => [{
          'name'    => 'does_not_exist',
          'version' => '1.2.0',
        }],
      }
    end

    it { is_expected.to compile.and_raise_error(/Unrecognised component: does_not_exist/) }
  end
end
