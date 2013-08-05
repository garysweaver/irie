['4.0.0', '3.2.14'].each do |rails_version|
  appraise "rails_#{rails_version}" do
    gem 'rails', rails_version
    gem 'json_spec'
    if rails_version.start_with?('3.')
      gem 'strong_parameters'
    end
  end
end
