# This file is copied to spec/ when you run 'rails generate rspec:install'
unless ENV['NO_COVERAGE']
  require 'simplecov'

  # Report code coverage to codeclimate
  if ENV['CODECLIMATE_REPO_TOKEN']
    require "codeclimate-test-reporter"
    CodeClimate::TestReporter.start
  end

  # On circleci change the output dir to the artifacts
  if ENV['CIRCLE_ARTIFACTS']
    SimpleCov.coverage_dir File.join("..", "..", "..", ENV['CIRCLE_ARTIFACTS'], "coverage")
  end

  SimpleCov.start 'rails' do
    add_group "Policies", "app/policies"
    add_group "Services", "app/services"
    add_group "Validators", "app/validators"

    if defined?(CodeClimate)
      formatter SimpleCov::Formatter::MultiFormatter[
        SimpleCov::Formatter::HTMLFormatter,
        CodeClimate::TestReporter::Formatter
      ]
    end
  end
end

ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'webmock/rspec'
require 'shoulda-matchers'
require 'database_cleaner'

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {
    phantomjs_logger: File.open("#{Rails.root}/log/test_phantomjs.log", "a"),
  })
end

Capybara.javascript_driver = :poltergeist

WebMock.disable_net_connect!(allow_localhost: true, allow: ['codeclimate.com'])

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false

  config.before :each do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
    ActionMailer::Base.deliveries = []
  end

  config.after do
    DatabaseCleaner.clean
  end

  config.include HelperMethods

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  config.disable_monkey_patching!

  config.include WaitForAjax, type: :feature
end
