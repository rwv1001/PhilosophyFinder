class DomainCrawlersController < ApplicationController
  def index
    logger.info "DomainCrawlersController index called with method #{params[:method]}"
    @users = User.all
    @domain_crawler = current_domain_crawler

    case params[:method]
      when "set_header"
        logger.info "DomainCrawlersController case set_header"

      when "index"
              logger.info "DomainCrawlersController case index"
      else
                    logger.info "DomainCrawlersController case else"
    end

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

  def search
    logger.info "DomainCrawlersController search called"
    logger.info "check #{params[:row_in_list]}"
    search_query = SearchQuery.new();
    search_query.create(params, current_user);

    search_query.search(params[:row_in_list]);

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
         logger.info "DomainCrawlersController create, before redirect"
         redirect_to domain_crawlers_url, notice: "Domain Analysis of #{@domain_crawler.domain_home_page} was successfull!"
       else
         logger.info "crawl failure"
         @domain_crawler.destroy
         logger.info "DomainCrawlersController create, before redirect"
         redirect_to domain_crawlers_url, notice: "Domain Analysis failed of  #{@domain_crawler.domain_home_page} failed. Is the domain address correct?"
       end
    end


  end

  def set_header
    logger.info "set_Header begin"

    @crawler_page_id = params[:id]
    @old_crawler_page_id = current_page;

    new_crawler_page = CrawlerPage.find_by_id(@crawler_page_id)
    current_user.current_domain_crawler_id = new_crawler_page.domain_crawler.id
    current_user.current_page = @crawler_page_id
    current_user.save
    logger.info "new crawler_page = #{@crawler_page_id}, domain_crawler = #{current_domain_crawler.id}"
    logger.info "set_Header end"
    respond_to do |format|
      format.js
    end
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
