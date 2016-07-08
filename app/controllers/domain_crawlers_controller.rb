class DomainCrawlersController < ApplicationController
  def index
    logger.info "DomainCrawlersController index called"
    @users = User.all
    @domain_crawler = current_domain_crawler
   # @crawl_results = DomainCrawler.crawl(params[:domain], current_user.id)
   # flash.now.alert = @crawl_results
   # redirect_to action: "show", id: current_domain_crawler
  end

  def new
    logger.info "DomainCrawlersController new called"
    @users = User.all
    @domain_crawler = DomainCrawler.new


 #   logger.info "DomainCrawlersController new called @domain_crawler id set to #{@domain_crawler.id}"
  end



  def create
    logger.info "DomainCrawlersController create called"

    logger.info "DomainCrawlersController params inspect #{domain_crawler_params.inspect}"
    @domain_crawler = DomainCrawler.new(domain_crawler_params)
    logger.info "DomainCrawlersController @domain_crawler inspect #{@domain_crawler.inspect}"

    logger.info "DomainCrawlersController create, after new"
    if @domain_crawler.save
      logger.info "DomainCrawlersController create, after save, inspect #{@domain_crawler.inspect}"
      first_page_id = @domain_crawler.crawl
       if first_page_id  !=0
         logger.info "Crawl success first_id = #{first_page_id}"
         @domain_crawler.crawler_page_id = first_page_id
         @domain_crawler.save

         current_user.current_domain_crawler_id = @domain_crawler.id
         current_user.save
       else
         logger.info "crawl failure"
         @domain_crawler.destroy
       end
    end
    logger.info "DomainCrawlersController create, before redirect"
    redirect_to domain_crawler_path, notice: "Thank you for creating a new domain!"

  end

  def show
    logger.info "DomainCrawlersController show called"
    @domain_crawler = current_domain_crawler

    respond_to do |format|
      format.html # show.html.erb

    end
  end

  def domain_crawler_params
    logger.info "DomainCrawlersController domain_crawler_params called"
    params.require(:domain_crawler).permit(:user_id, :domain_home_page, :short_name, :description)
  end
end
