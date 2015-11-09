# Fact: appserver_path.rb
#
# Purpose: get the path to the installed application server
Facter.add(:appserver_path) do
  setcode do
    # I think a fact is the wrong mechanism for delivering this infomation dynamically
    # (for example by executing 'which asadmin' on the command line) since facts are
    # evaluated at manifest compile time -- before the app server has been installed.
    # I guess there's no reason why we can't just pass an 'install_dir' param to the
    # glassfish module (or wildfly if/when we migrate) and then use the same string
    # for whatever needs this fact.
    # In any event, this is a quick and brittle workaround which will do for now.
    '/usr/local/glassfish-4.0'
  end
end
