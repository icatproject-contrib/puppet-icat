require 'spec_helper'

# Start to describe glassfish::init class
describe 'icat' do
  describe 'with default param values' do
    it do
      should compile.with_all_deps()

      should create_class('icat')
    end
  end
end
