require 'spec_helper'

describe 'icat::create_component' do
  let(:facts) { {
    :osfamily => 'RedHat'
  } }

  let (:default_params) do
    {
      'component_name' => 'icat.server',
      'templates'      => [
        "icat.properties.epp",
        "icat-setup.properties.epp",
        "icat.log4j.properties.epp",
      ],
      'tmp_dir'        => '/tmp',
      'version'        => '4.5.0',
    }
  end

  context 'with default params' do
    let(:title) { 'icat.server' }
    let(:params) { default_params }

    it do
      should compile.with_all_deps()
    end
  end
end
