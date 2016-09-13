class DomainCrawlersController < ApplicationController
  def index
    @result_str = ""
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
    @result_str = ""


    #   logger.info "DomainCrawlersController new called @domain_crawler id set to #{@domain_crawler.id}"
  end

  def crawler_debug
    crawler_page = CrawlerPage.where(id: 3)
    logger.info "crawler_page: #{crawler_page.inspect}"
    descendents = crawler_page.root.descendants.arrange
    descendents.each do |descendent|
  #    logger.info "Descendent is #{descendent}"
    end
    x =y
  end
  def tidy_up
    logger.info "tidy up params: #{params.inspect}"
    SearchQuery.tidy_up(params[:tidy_user_id])
    respond_to do |format|
      format.js
    end
  end

  def process_more_results
    logger.info "process_more_results: #{params.inspect}"
    process_output = SearchQuery.process_more_results(params[:more_results_query_id])
    @unprocessed_sentence_count = process_output[:unprocessed_sentence_count]
    @found_results = process_output[:found_results]
    @first_index = [1, params[:more_results_first_result_id].to_i - process_output[:absolute_first]+1].max
    @last_index = [params[:more_results_last_result_id].to_i, process_output[:absolute_last]].min - process_output[:absolute_first]+1
#    logger.info "process_more_results @first_index= #{ @first_index }, @last_index = #{@last_index}, @unprocessed_sentence_count = #{@unprocessed_sentence_count}, "
# logger.info "params[:more_results_last_result_id] = #{params[:more_results_last_result_id]}, process_output[:absolute_first] = #{process_output[:absolute_first]}, process_output[:absolute_last] = #{process_output[:absolute_last]}"

    respond_to do |format|
      format.js
    end
  end

  def previous_search
    logger.info "previous_search: #{params.inspect}"
    current_index = 0
    more_resultsa(params[:prev_query_id], current_index, MAX_DISPLAY)
    respond_to do |format|
      format.js
    end
  end

  def more_resultsa(query_id, current_index, range)
    fetch_output = SearchQuery.fetch(query_id, current_index, range)
    @search_results = fetch_output[:fetch_results]
    @query_id = query_id
    if @search_results.length > 0
      @first_result_id = @search_results[0].id
      @last_result_id = @search_results[-1].id
      @absolute_last = fetch_output[:absolute_last]
      @absolute_first =fetch_output[:absolute_first]
      @found_results = fetch_output[:found_results]
  #    logger.info "more_result - first item: #{@search_results[0].inspect}"

      if @first_result_id > fetch_output[:absolute_first]
        @show_previous = true
      else
        @show_previous = false
      end
      @unprocessed_sentence_count = fetch_output[:unprocessed_sentence_count]
      if @last_result_id < fetch_output[:absolute_last] or @unprocessed_sentence_count > 0
        @show_next = true
      else
        @show_next =false
      end
    else
      @first_result_id =0
      @last_result_id = 0
      @absolute_last = 0
      @absolute_first = 0
      @found_results = 0
      @show_next =false
      @show_previous = false
    end

  end

  def more_results
    more_resultsa(params[:results_query_id].to_i, params[:results_current_index].to_i, params[:results_range].to_i)

    respond_to do |format|
      format.js
    end
  end

  def search
    logger.info "DomainCrawlersController search called"
#    logger.info "check #{params[:row_in_list]}"
    search_query = SearchQuery.new();
    search_query.create(params, current_user);
    @query_id = search_query.id
    #  crawler_debug


    @domain_length = 0;
    @search_results = [];
    @unprocessed_sentence_count = 0
    @first_result_id = 0
    @last_result_id = 0
    @show_previous = false
    @show_next = false

    if params[:row_in_list] != nil
      search_output = search_query.search(params[:row_in_list]);

      if search_output[:search_results].length >0
        @search_results = search_output[:search_results]
        @first_result_id = @search_results[0].id
        @last_result_id = @search_results[-1].id
        @show_previous = false
        if search_output[:unprocessed_sentence_count] >0
          @show_next = true
        else
          @show_next = false
        end
        @unprocessed_sentence_count = search_output[:unprocessed_sentence_count]
     #   logger.info "Search @first_result_id = #{ @first_result_id }, @last_result_id = #{@last_result_id}, @unprocessed_sentence_count = #{@unprocessed_sentence_count} "


      end
      @truncate_length = search_output[:truncate_length]
      @domain_length = params[:row_in_list]
    end

    respond_to do |format|
      format.js
    end

  end


  def create
    logger.info "DomainCrawlersController create called"
    @result_str = ""
   # logger.info "DomainCrawlersController params inspect #{domain_crawler_params.inspect}"
    @domain_crawler = DomainCrawler.new(domain_crawler_params)
  #  logger.info "DomainCrawlersController @domain_crawler inspect #{@domain_crawler.inspect}"

 #   logger.info "DomainCrawlersController create, after new"
    if @domain_crawler.save
  #    logger.info "DomainCrawlersController create, after save, inspect #{@domain_crawler.inspect}"
      first_page_id = @domain_crawler.crawl
      if first_page_id !=0
    #    logger.info "Crawl success first_id = #{first_page_id}"
        @domain_crawler.crawler_page_id = first_page_id
        @domain_crawler.save

        current_user.current_domain_crawler_id = @domain_crawler.id
        current_user.save
     #   logger.info "DomainCrawlersController create, before redirect"
        redirect_to domain_crawlers_url, notice: "Domain Analysis of #{@domain_crawler.domain_home_page} was successfull!"
      else
     #   logger.info "crawl failure"
        @domain_crawler.destroy
     #   logger.info "DomainCrawlersController create, before redirect"
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
    @result_str = ""

    @crawler_page_id = params[:id]
    @old_crawler_page_id = current_page;

    new_crawler_page = CrawlerPage.find_by_id(@crawler_page_id)
    current_user.current_domain_crawler_id = new_crawler_page.domain_crawler.id
    current_user.current_page = @crawler_page_id
    current_user.save
  #  logger.info "new crawler_page = #{@crawler_page_id}, domain_crawler = #{current_domain_crawler.id}"
  #  logger.info "set_Header end"
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
#    logger.info "move_group ancestors: #{ancestor_ids}, group_name_id = #{group_name.id}"
    if ancestor_ids.index(group_name.id) != nil

      @result_str = "You cannot move a parent to one of its children"
    else
      group_name.parent_id = new_parent.id
      group_name.save;
      @result_str = ""
    end
 #   logger.info "move_group result_str = #{@result_str}"

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
    @result_str = ""
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
 #   logger.info "group_action result_str = #{@result_str}"
    respond_to do |format|
      format.js
    end

  end

  def domain_action
    logger.info "domain_action begin"
    @result_str = ""
    case params[:commit]
      when "Rename Page"
        rename_domain(params)
      when "Fix Domain"
        fix_domain(params)
      when "Move Selected"
        move_domain(params)
      when "Remove Domain"
        remove_domain(params)
      else
        remove_domain(params)
    end
  #  logger.info "domain_action result_str = #{@result_str}"
    respond_to do |format|
      format.js
    end
  end
  def fix_domain(params)
    logger.info "fix_domain begin"
    @result_str = "hello"
    domain_crawler_id = CrawlerPage.find_by_id(params[:domain_radio]).domain_crawler_id;
    domain_crawler = DomainCrawler.find_by_id(domain_crawler_id);
    result_str = domain_crawler.fix_domain()

 #   call_rake :fix_domain, :domain_crawler_id => domain_crawler_id
    flash[:notice] = "fixing domain"



  #  logger.info "fix_domain result: #{@result_str}"
    @selected = DOMAIN_ACTION[:fix_domain]
  end

  def remove_domain(params)
    logger.info "remove_domain begin"
    @selected = DOMAIN_ACTION[:remove_domain]
    crawler_page_name = CrawlerPage.find_by_id(params[:remove_domain])
    if crawler_page_name != nil
      if crawler_page_name.parent_id == nil
        DomainCrawler.destroy(crawler_page_name.domain_crawler.id)
        @result_str = ""
        @crawler_parent_id = nil
        current_user.current_domain_crawler_id = DEFAULT_PAGE[:domain_crawler]

      else
        @crawler_parent_id = crawler_page_name.parent_id
        CrawlerPage.destroy(crawler_page_name.id)
        @result_str = ""
      end
    else
      @result_str = "Page already deleted"
    end
  end

  def rename_domain(params)
    crawler_page_name = CrawlerPage.find_by_id(params[:domain_radio]);
    crawler_page_name.name = params[:domain_action_name];
    crawler_page_name.save
    if crawler_page_name.parent_id == nil
      domain_crawler = crawler_page_name.domain_crawler
      domain_crawler.short_name = params[:domain_action_name];
      domain_crawler.save
    end
    @selected = DOMAIN_ACTION[:rename]
    @crawler_parent_id = crawler_page_name.parent_id
    @result_str = ""
  end

  def move_domain(params)
    crawler_page_name = CrawlerPage.find_by_id(params[:domain_radio]);
    new_parent = CrawlerPage.find_by_id(params[:move_location_domain_radio]);
    ancestor_ids = new_parent.ancestor_ids
 #   logger.info "move_domain ancestors: #{ancestor_ids}, domain_name_id = #{crawler_page_name.id}"
    if ancestor_ids.index(crawler_page_name.id) != nil

      @result_str = "You cannot move a parent to one of its children"
    else
      crawler_page_name.parent_id = new_parent.id
      crawler_page_name.save;
      @result_str = ""
    end
 #   logger.info "move_domain result_str = #{@result_str}"

    @selected = DOMAIN_ACTION[:move_domain]
    @crawler_parent_id = crawler_page_name.parent_id

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
    @result_str = ""
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
