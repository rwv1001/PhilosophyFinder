class SearchResultsController < ApplicationController
  def index
    @search_results = SearchResult.search(params[:search])
  end
end
