module Puppet::Parser::Functions
  newfunction(:get_all_authenticators, :type => :rvalue, :doc => <<-EOS
    TODO: Documentation goes here.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "get_all_authenticators(): Wrong number of arguments " +
      "given (#{arguments.size} when 1 was required).") if arguments.size != 1

    components = arguments[0]

    authenticators = components
      .map { |comp| comp['name'] }
      .reject { |comp_name| comp_name !~ /^(authn\.)(.*)$/ }
      .map { |auth_comp_name| auth_comp_name[6..-1] }

    return authenticators
  end
end
