require "spec_helper"

describe Facter::Util::Fact do
  before {
    Facter.clear
  }

  describe "appserver_path" do
    context 'returns the path of the application server' do
      it do
        Facter::Util::Resolution.expects(:which).with("asadmin").returns('/usr/local/glassfish-4.0/glassfish/bin/asadmin')

        expect(Facter.value(:appserver_path)).to eq('/usr/local/glassfish-4.0')
      end
    end
  end
end
