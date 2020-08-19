# frozen_string_literal: true

begin
  require 'active_support/lazy_load_hooks'

  ActiveSupport.on_load :active_record do
    require "bali"
    ::ActiveRecord::Base.send :extend, Bali::Statics::Record
  end
rescue LoadError
end
