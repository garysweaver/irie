# TODO: switch to minitest spec. 4.1.0 in master breaks on rspec.
# undefined method `assertions' for #<RSpec::Rails::TestUnitAssertionAdapter::AssertionDelegator:0x007f9656f7b9a0>
# .../gems/minitest-5.0.8/lib/minitest/assertions.rb:126:in `assert'
#appraise "rails_edge" do
#  gem 'rails', github: 'rails/rails'
#  gem 'json_spec'
#end

['4.0'].each do |rails_version|
  appraise "rails_#{rails_version}" do
    gem 'rails', rails_version
  end
end
