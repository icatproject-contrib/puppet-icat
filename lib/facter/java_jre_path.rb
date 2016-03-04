# Fact: java_jre_path
#
# Purpose: get the path to the jre
Facter.add(:java_jre_path) do
  setcode do
    '/usr/java/jdk1.8.0_74/jre'
  end
end
