# frozen_string_literal: true

require 'active_support/lazy_load_hooks'

ActiveSupport.on_load :active_record do
  require "bali"
  ::ActiveRecord::Base.send :include, Bali::Authorizer
  ::ActiveRecord::Base.send :extend, Bali::Statics::Authorizer
end
