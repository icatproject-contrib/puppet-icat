# Fact: java_jre_path
#
# Purpose: get the path to the jre
Facter.add(:java_jre_path) do
  setcode do
    '/usr/java/jdk1.7.0_79/jre'
  end
end
