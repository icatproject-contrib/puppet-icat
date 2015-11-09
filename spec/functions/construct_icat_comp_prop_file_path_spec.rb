require 'spec_helper'

describe 'construct_icat_comp_prop_file_path' do
  it { should run.with_params('/tmp/icat.server-4.5.0-distro', 'icat.server', 'test.properties.epp')
    .and_return('/tmp/icat.server-4.5.0-distro/icat.server/test.properties') }
  it { should run.with_params('wrong', 'number', 'of', 'arguments').and_raise_error(Puppet::ParseError) }
end
  