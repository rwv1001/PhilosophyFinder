require 'uri'
require 'net/http'

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



    uri = URI("http://www.google.com/recaptcha/api/verify")
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    verify_request = Net::HTTP::Post.new(uri.path)

    verify_request["secret"]        =  Rails.application.secrets.recaptcha_secret_key
    verify_request["remoteip"]  = request.remote_ip, #ip address of the user
        verify_request["challenge"] = params[:recaptcha_challenge_field], #recaptcha challenge field value
        verify_request["response"]  = params[:recaptcha_response_field] # recaptcha response field value

    response = https.request(request)
    puts response

    if @user.save and verify_recaptcha(model: @user)
      cookies[:auth_token] = @user.auth_token

      redirect_to new_domain_crawler_path
    else
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
