module Puppet::Parser::Functions
  newfunction(:construct_icat_comp_prop_file_path, :type => :rvalue, :doc => <<-EOS
    TODO: Documentation goes here.
    EOS
  ) do |arguments|

    raise(Puppet::ParseError, "construct_icat_comp_prop_file_path(): Wrong number of arguments " +
      "given (#{arguments.size} when 3 were required).") if arguments.size != 3

    extracted_path  = arguments[0]
    inner_comp_name = arguments[1]
    template_path   = arguments[2]

    return File.join(
      extracted_path,
      inner_comp_name,
      File.basename(template_path, File.extname(template_path))
    )
  end
end
