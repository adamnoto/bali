module ApplicationHelper
  def can_send_message?
    UserRules.can?(:send_message)
  end

  def cant_see_banner?
    UserRules.cant?(:see_banner)
  end
end
