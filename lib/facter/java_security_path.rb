# Fact: java_security_path
#
# Purpose: get the path to the security directory
Facter.add(:java_security_path) do
  setcode do
    Facter.value(:java_jre_path) + '/lib/security'
  end
end
