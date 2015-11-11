## Note:

This directory is here as a result of being unable to get the tests at `spec/defines/create_component_spec.rb` to recognise templates when placed at `spec/fixtures/templates` which is where they should actually be.  An example of a Puppet module that does this correctly is `puppet-consul_template`:

https://github.com/gdhbashton/puppet-consul_template

Note the `test_template` file (nested inside a directory named after the module) at:

https://github.com/gdhbashton/puppet-consul_template/tree/master/spec/fixtures/templates

Nested directory or no, I could not get this to work properly for the ICAT module after two hours of effort.  Extremely annoying.  I *think* this *may* have something to do with the fact that if there are any templates *at all* in any of the modules at `spec/fixtures/modules`, then Puppet will refuse to look at the directory specified in the `spec_helper.rb` with:

```ruby
fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.template_dir = File.join(fixture_path, 'templates')
end
```

If I ever feel like life is not short enough, or perhaps I just want to prolong the suffering, then a starting point for further investigation may be to download the `puppet-consul_template` module and run the tests, then add a module such as `glassfish` which has it's own templates as see if that has any effect.

# EDIT

I think I may have solved the issue (do a git blame on this line for the commit with the fix.)  TODO: When I have time I should move these templates to the fixtures directory.
