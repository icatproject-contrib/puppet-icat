# Fact: icat_domain_path
#
# Purpose: get the path to the ICAT application server domain
Facter.add(:icat_domain_path) do
  setcode do
    File.join(Facter.value(:appserver_path), 'glassfish', 'domains', 'icat')
  end
end
