class UsersController < ApplicationController
  def index
  end

  def show
    @user = User.find params[:id]
    @friend = User.find params[:friend_id]

    if can? @user, :see_timeline, @friend
      render plain: "ok"
    else
      render plain: "prohibited"
    end
  end
end
