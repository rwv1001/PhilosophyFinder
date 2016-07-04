class UsersController < ApplicationController
  def new
    @user = User.new
  end



  def create
    @user = User.new(user_params)
    if @user.save
      cookies[:auth_token] = @user.auth_token
      redirect_to domain_crawlers_path, notice: "Thank you for signing up!"
    else
      render "new"
    end
  end

  def index
    @users = User.all
  end

  private

  def user_params
    params.require(:user).permit(:email, :first_name, :second_name, :password, :password_confirmation)
  end
end
