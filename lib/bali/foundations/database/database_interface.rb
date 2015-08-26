class Bali::Database::DatabaseInterface
  # activerecord, mongoid, or any other adapter name
  def adapter_name
    raise Bali::Error, "adapter_name is not yet defined/overridden" 
  end

  def rule_adapter
    raise Bali::Error, "rule_adapter is not yet defined/overridden"
  end
end
