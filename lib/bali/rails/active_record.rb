# frozen_string_literal: true

require 'active_support/lazy_load_hooks'

ActiveSupport.on_load :active_record do
  require "bali"
  ::ActiveRecord::Base.send :extend, Bali::Statics::ActiveRecord
end
