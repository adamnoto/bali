# frozen_string_literal: true

require 'active_support/lazy_load_hooks'

ActiveSupport.on_load :action_controller do
  require "bali"
  ::ActionController::Base.send :include, Bali::Statics::Authorizer
end
