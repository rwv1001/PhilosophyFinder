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

    if params[:row_in_list]== nil
      @domain_length = 0;
      @search_results = [];
    else
      @search_results = search_query.search(params[:row_in_list]);
      @domain_length = params[:row_in_list]
    end


    respond_to do |format|
      format.js
    end

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
  def delete_result
    logger.info "delete_result begin"
    @delete_id = params[:id]
    SearchResult.destroy(@delete_id)
    respond_to do |format|
      format.js
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

  def remove_group_result
    logger.info "remove_group_result begin"
    @group_search_result_list = params[:group_search_result_list].map(&:to_i)
    @group_search_result_list.each do |group_search_result|
      GroupElement.destroy(group_search_result)
    end
    respond_to do |format|
      format.js
    end
  end

  def display_group
    logger.info "display_group begin"
    @group_id = params[:id]
    respond_to do |format|
      format.js
    end
  end

  def create_group(params)
    new_group = GroupName.new
    new_group.name = params[:group_action_name]
    new_group.parent_id = params[:group_radio]
    new_group.user_id = current_user.id
    new_group.save
    @selected = GROUP_ACTION[:new_group]
    @group_parent_id = new_group.parent_id
    @result_str = ""
  end


  def rename_group(params)
    group_name = GroupName.find_by_id(params[:group_radio]);
    group_name.name = params[:group_action_name];
    group_name.save
    @selected = GROUP_ACTION[:rename]
    @group_parent_id = group_name.parent_id
    @result_str = ""
  end

  def move_group(params)
    group_name = GroupName.find_by_id(params[:group_radio]);
    new_parent = GroupName.find_by_id(params[:move_location_group_radio]);
    ancestor_ids = new_parent.ancestor_ids
    logger.info "move_group ancestors: #{ancestor_ids}, group_name_id = #{group_name.id}"
    if ancestor_ids.index(group_name.id) != nil

      @result_str = "You cannot move a parent to one of its children"
    else
      group_name.parent_id = new_parent.id
      group_name.save;
      @result_str = ""
    end
    logger.info "move_group result_str = #{@result_str}"

    @selected = GROUP_ACTION[:move_group]
    @group_parent_id = group_name.parent_id

  end

  def remove_group(params)
    @selected = GROUP_ACTION[:remove_group]
    group_name = GroupName.find_by_id(params[:remove_group])
    if group_name != nil
      @group_parent_id = group_name.parent_id
      GroupName.destroy(group_name.id)
      @result_str = ""
    else
      @result_str = "Group already deleted"
    end
  end

  def group_action
    logger.info "group_action begin"
    case params[:commit]
      when "Create Group"
        create_group(params)
      when "Move Selected"
        move_group(params)
      when "Rename Group"
        rename_group(params)
      when "Remove Group"
        remove_group(params)
      else
        remove_group(params)
    end
    logger.info "group_action result_str = #{@result_str}"
    respond_to do |format|
      format.js
    end

  end

  def add_result
    logger.info "add_result begin"
    group_name = GroupName.find_by_id(params[:add_elements_group_id]);
    @result_count = group_name.AddResults(params[:search_result_list], current_user.id)
    @result_str = "Results added to #{group_name.name}: #{@result_count[:add_count]}; Already present: #{@result_count[:present_count]}"
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
