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
  def current_page
    if current_user != nil
      @current_page = @current_user.current_page
      return @current_page
    else
      return PAGE[:users]
    end
  end

  def current_search_query
    if (current_user != nil) then
      if SearchQuery.exists?(user_id: current_user) then
        return @current_search_query = SearchQuery.where(["user_id = ?", current_user]).last.id
      end

    end
    return @current_search_query = SearchQuery.find_by_id(DEFAULT_PAGE[:search_query])
  end

  def current_domain_crawler
    (current_user != nil) ?
        current_domain_crawler_id = current_user.current_domain_crawler_id :
        current_domain_crawler_id = DEFAULT_PAGE[:domain_crawler]

    @current_domain_crawler = DomainCrawler.find_by_id( current_domain_crawler_id)
  end

  helper_method :current_user
  helper_method :current_page
  helper_method :current_search_query
  helper_method :current_domain_crawler

  def authorize
    redirect_to login_url, alert: "Not authorized" if current_user.nil?
  end

end
