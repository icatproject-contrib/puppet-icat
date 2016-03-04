module Puppet::Parser::Functions
  newfunction(:construct_authenticator_jndi_entries, :type => :rvalue, :doc => <<-EOS
    TODO: Documentation goes here.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "construct_authenticator_jndi_entries(): Wrong number of arguments " +
      "given (#{arguments.size} when 1 was required).") if arguments.size != 1

    components = arguments[0]

    jndi_entries = components
      .map { |comp| [comp['name'], comp['version']] }
      .reject { |comp_name, version| comp_name !~ /^(authn\.)(.*)$/ }
      .map { |auth_comp_name, version| [auth_comp_name[6..-1], version] }
      .map { |auth_name, version| "authn.#{auth_name}.jndi java:global/authn.#{auth_name}-#{version}/#{auth_name.upcase}_Authenticator" }

    return jndi_entries
  end
end
