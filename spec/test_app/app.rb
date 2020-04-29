# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'

require 'active_record'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'ostruct'

# config
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

module TestApp
  class Application < Rails::Application
    config.secret_token = "who_will_keep_it_secure_if_not_us"
    config.session_store :cookie_store, key: "_testapp_session"
    config.active_support.deprecation = :log
    config.eager_load = false
    config.action_dispatch.show_exceptions = false
    config.root = File.dirname(__FILE__)

    config.action_mailer.delivery_method = :test
  end
end

TestApp::Application.initialize!

# routes
require_relative "routes"

# transaction
require_relative "app/models/user"
require_relative "app/models/transaction"

# controllers
require_relative "app/controllers/application_controller"
require_relative "app/controllers/users_controller"
require_relative "app/controllers/api/users_controller"

# migrations
require_relative "migrations"
