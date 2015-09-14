module Bali::DatabaseIntegrator
  extend self

  # list all database as configured through enable
  DATABASE_PLUGINS = {}

  # work in progres:
  # so, when a database is :enable-d through config
  # it is registered here. all transaction should get
  # the adapater from this integrator, which then delegated
  # to a class inherit from Bali::Database::DatabaseInterface
end
