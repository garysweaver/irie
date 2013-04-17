# broken for now
#appraise 'rails-edge' do
#  gem 'rails', :git => 'git://github.com/rails/rails.git'
#  gem 'json_spec'
#end

['4.0.0.beta1', '3.2.13', '3.1.12'].each do |rails_version|
  appraise "rails_#{rails_version}" do
    gem 'rails', rails_version
    gem 'json_spec'
    if rails_version.start_with?('3.')
      gem 'strong_parameters'
    end
  end
end
