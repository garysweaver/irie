appraise 'rails31' do
  gem 'rails', '~> 3.1.0'
end

appraise 'rails32' do
  gem 'active_model_serializers', '0.7.0'
  gem 'cancan', '~> 1.6.7'
  gem 'strong_parameters', '~> 0.1.3'
  gem 'rails', '3.2.11'
end

unless RUBY_VERSION == '1.8.7'
  appraise 'rails40' do
    gem 'activerecord-deprecated_finders'
    gem 'active_model_serializers', '0.7.0'
    gem 'cancan', '~> 1.6.7'
    gem 'rails', '~> 4.0.0.beta1'
  end
end
