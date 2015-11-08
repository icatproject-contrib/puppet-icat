# Fact: appserver_path.rb
#
# Purpose: get the path to the installed application server
Facter.add(:appserver_path) do
  setcode do
    File.expand_path(File.join(Facter::Util::Resolution.which('asadmin'), '..', '..', '..'))
  end
end
