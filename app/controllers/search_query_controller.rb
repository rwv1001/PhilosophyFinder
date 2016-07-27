class SearchQueryController < ApplicationController
  def new
    logger.info "SearchQueryController new"
    logger.flush
  end
  def show
    logger.info "SearchQueryController show"
    logger.flush
  end

  def create
    logger.info "SearchQueryController create"
    logger.flush
  end
end
