### Setup

    gem install bundler
    bundle install

### Refresh Appraisal Gemfiles and Test w/Rails

    bundle exec rake appraisal:cleanup appraisal:gemfiles appraisal:install
    rake appraisal:rails31 spec
    rake appraisal:rails32 spec
    rake appraisal:rails40 spec
