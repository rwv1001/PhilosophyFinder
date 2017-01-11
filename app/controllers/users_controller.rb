class UsersController < ApplicationController
  def new
    logger.info "UsersController new called"
    @user = User.new
  end



  def create
    logger.info "UsersController create called"
    index
    logger.info "User params inspect #{user_params.inspect}"

    @user = User.new(user_params)
    if @user.save and verify_recaptcha(model: @user)
      cookies[:auth_token] = @user.auth_token
      logger.info "catpcha verified"

      redirect_to new_domain_crawler_path
    else
      logger.info "catpcha unverified"
      render "new"
    end
  end

  def index
    logger.info "UsersController index called"
    @users = User.all
  end

  private

  def user_params
    logger.info "UsersController user_params called"
    params.require(:user).permit(:email, :first_name, :second_name, :password, :password_confirmation)
  end
end
