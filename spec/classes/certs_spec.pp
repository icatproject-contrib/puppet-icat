require 'spec_helper'

describe 'icat::certs' do

  context 'with jssecacerts_path => /java/jssecacerts' do
    let(:params) { :jssecacerts_path => '/java/jssecacerts' }

    it do
      should contain_exec('setup_security_certificates').with({
        'unless' => 'test -f /java/jssecacerts'
      })
  end
end
