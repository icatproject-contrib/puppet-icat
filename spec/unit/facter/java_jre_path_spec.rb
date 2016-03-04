require "spec_helper"

describe Facter::Util::Fact do
  before {
    Facter.clear
  }

  describe "java_jre_path" do
    context 'always returns the same path' do
      it do
        # The fact is super simple for now, but if we were to have it change based on java
        # version downloaded, or for differences between OS's, then the official Puppetlabs
        # java module has some nice example code:
        #
        # https://github.com/puppetlabs/puppetlabs-java/blob/master/spec/unit/facter/java_version_spec.rb
        expect(Facter.value(:java_jre_path)).to eq('/usr/java/jdk1.8.0_74/jre')
      end
    end
  end
end
