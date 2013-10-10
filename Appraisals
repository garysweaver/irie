# TODO: switch to minitest spec. 4.1.0 in master breaks on rspec.
# undefined method `assertions' for #<RSpec::Rails::TestUnitAssertionAdapter::AssertionDelegator:0x007f9656f7b9a0>
# .../gems/minitest-5.0.8/lib/minitest/assertions.rb:126:in `assert'
#appraise "rails_edge" do
#  gem 'rails', github: 'rails/rails'
#  gem 'json_spec'
#end

# note: leaving this as appraisal setup for now, even though only testing one version of Rails,
# because 4.1 is coming soon.
[4.0].each do |version|
  appraise "rails_#{version}" do
    gem 'rails', "~> #{version}"
  end
end
