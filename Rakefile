require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

exclude_paths = [
  "vendor/**/*",
  "spec/**/*",
]
PuppetSyntax.exclude_paths = exclude_paths

if ENV.key?('PARSER')
  PuppetSyntax.future_parser = ENV['PARSER'] == 'future'
else
  PuppetSyntax.future_parser = false
end

# Puppet-Lint 1.1.0
Rake::Task[:lint].clear
PuppetLint::RakeTask.new :lint do |config|
  config.ignore_paths = exclude_paths 
  config.log_format = '%{path}:%{linenumber}:%{check}:%{KIND}:%{message}'
  config.disable_checks = [ "class_inherits_from_params_class", "80chars" ]
  config.fail_on_warnings = true
  config.relative = true
end

# Using librarian-puppet instead of r10k since it automatically downloads a module's dependencies.
task :librarian_spec_prep do
 sh "librarian-puppet install --path=spec/fixtures/modules/"
end
task :spec_prep => :librarian_spec_prep

desc "Run acceptance tests"
RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = 'spec/acceptance'
end

desc "Run syntax, lint, and spec tests."

test_commands = [
  :lint,
  :spec,
]

if Gem.loaded_specs["puppet"].version >= Gem::Version.create('4.0')
  test_commands.push(:syntax)
end

task :test => test_commands
