class DomainCrawlersController < ApplicationController
  def index
    @crawl_results = DomainCrawler.crawl(params[:domain], current_user.id)
  end
end
