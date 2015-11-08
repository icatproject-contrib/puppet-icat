# Fact: java_keytool_path
#
# Purpose: get the path to the security directory
Facter.add(:java_keytool_path) do
  setcode do
    Facter.value(:java_jre_path) + '/bin/keytool'
  end
end
