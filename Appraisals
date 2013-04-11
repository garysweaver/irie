['4.0.0.beta1'].each do |rails_version|
  appraise "rails_#{rails_version}" do
    gem "rails", rails_version
    gem 'json_spec'
    #gem 'autolog'    
  end
end

['3.2.13', '3.1.12'].each do |rails_version|
  appraise "rails_#{rails_version}" do
    gem "rails", rails_version
    gem 'strong_parameters'
    gem 'json_spec'
    #gem 'autolog'
  end
end
