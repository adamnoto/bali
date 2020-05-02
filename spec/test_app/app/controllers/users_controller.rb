class UsersController < ApplicationController
  def index
    @current_user = params[:id] ? User.find(params[:id]) : User.create
    render file: Rails.root.join("app/views/users/index")
  end

  def index_no_current_user
    @current_user = User.create
    render file: Rails.root.join("app/views/users/index_no_current_user")
  end

  def show
    @user = User.find params[:id]
    @friend = User.find params[:friend_id]

    if can? @user, :see_timeline, @friend
      render plain: "ok"
    else
      render plain: "prohibited", status: :unauthorized
    end
  end
end
