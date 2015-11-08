require "spec_helper"

describe Facter::Util::Fact do
  before {
    Facter.clear
  }

  describe "icat_domain_path" do
    context 'returns the path of the icat application server domain' do
      before :each do
        Facter.fact(:appserver_path).stubs(:value).returns('/usr/local/glassfish-4.0')
      end

      it do
        expect(Facter.value(:icat_domain_path)).to eq('/usr/local/glassfish-4.0/glassfish/domains/icat')
      end
    end
  end
end
