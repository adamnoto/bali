# frozen_string_literal: true

require 'active_support/lazy_load_hooks'

ActiveSupport.on_load :action_controller do
  require "bali"
  ::ActionController::Base.send :include, Bali::Statics::Authorizer
  ::ActionController::Base.send :include, Bali::Statics::ScopeRuler

  if defined? ::ActionController::API
    ::ActionController::API.send :include, Bali::Statics::Authorizer
    ::ActionController::API.send :include, Bali::Statics::ScopeRuler
  end
end
