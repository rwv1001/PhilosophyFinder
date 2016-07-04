class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception



  private
  def current_user
   # if cookies[:auth_token]
   #   logger.debug "cookie = #{cookies[:auth_token]}"
   # else
   #   logger.debug "cookie undefined"
  #  end
    @current_user ||= User.find_by_auth_token!(cookies[:auth_token]) if cookies[:auth_token]
    #if @current_user
     # logger.debug "current_user = #{@current_user.id}"
   # else
    #  logger.debug "current_user undefined"
   # end
    return @current_user

  end
  helper_method :current_user

  def authorize
    redirect_to login_url, alert: "Not authorized" if current_user.nil?
  end

end
