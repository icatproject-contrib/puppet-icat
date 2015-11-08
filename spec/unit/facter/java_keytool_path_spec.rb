require "spec_helper"

describe Facter::Util::Fact do
  before {
    Facter.clear
  }

  describe "java_keytool_path" do
    context 'return path based on java_jre_path fact' do
      before :each do
        Facter.fact(:java_jre_path).stubs(:value).returns('/usr/java/jdk1.7.0_79/jre')
      end

      it do
        expect(Facter.value(:java_keytool_path)).to eq('/usr/java/jdk1.7.0_79/jre/bin/keytool')
      end
    end
  end
end
