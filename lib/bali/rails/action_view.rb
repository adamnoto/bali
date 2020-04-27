# frozen_string_literal: true

require 'active_support/lazy_load_hooks'

ActiveSupport.on_load :action_view do
  require "bali"
  ::ActionView::Base.send :include, Bali::Authorizer::Statics
end
