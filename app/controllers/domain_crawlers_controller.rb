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
    if params[:search_type] == "search_domains"
      @search_groups1 = false
    else
      @search_groups1 = true
    end


    @domain_length = 0;
    @search_results = [];
    @unprocessed_sentence_count = 0
    @first_result_id = 0
    @last_result_id = 0
    @show_previous = false
    @show_next = false


    search_output = search_query.search();

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
    @domain_length = 1
    crawler_range = CrawlerRange.where('user_id = ? and begin_id = ? and end_id = ?', current_user.id, CrawlerPage.first.id + 1, CrawlerPage.last.id).first
    if crawler_range
      @domain_length = 0
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
    if @domain_crawler.save
      case params[:new_domain_action]
        when "new_domain"


          #   logger.info "DomainCrawlersController create, after new"

          #    logger.info "DomainCrawlersController create, after save, inspect #{@domain_crawler.inspect}"
          first_page_id = @domain_crawler.crawl(params[:flow_str])


        when "grab_domain"
          first_page_id = @domain_crawler.grab_domain(params[:filter])
      end
      if first_page_id !=0
        #    logger.info "Crawl success first_id = #{first_page_id}"
        @domain_crawler.crawler_page_id = CrawlerPage.find_by_id(first_page_id).root.id
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
    user_paragraph_str = "SELECT * FROM user_paragraphs up WHERE up.user_id = #{current_user.id} AND\
 (SELECT COUNT(*) FROM group_elements ge WHERE ge.user_id = #{current_user.id} AND ge.paragraph_id = up.paragraph_id) = 0"
    delete_str = "DELETE FROM user_paragraphs up WHERE up.user_id = #{current_user.id} AND\
 (SELECT COUNT(*) FROM group_elements ge WHERE ge.user_id = #{current_user.id} AND ge.paragraph_id = up.paragraph_id) = 0"
    ActiveRecord::Base.connection.execute(delete_str)

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
    @group_selected = GROUP_ACTION[:new_group]
    @group_parent_id = new_group.parent_id
    @result_str = ""
  end


  def rename_group(params)
    group_name = GroupName.find_by_id(params[:group_radio]);
    group_name.name = params[:group_action_name];
    group_name.save
    @group_selected = GROUP_ACTION[:rename]
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

    @group_selected = GROUP_ACTION[:move_group]
    @group_parent_id = group_name.parent_id

  end

  def remove_group(params)
    @group_selected = GROUP_ACTION[:remove_group]
    group_name = GroupName.find_by_id(params[:remove_group])
    if group_name != nil
      @group_parent_id = group_name.parent_id
      GroupName.destroy(group_name.id)
      @result_str = ""
    else
      @result_str = "Group already deleted"
    end
  end

  def expand_contract_action
    crawler_page_id = params[:crawler_page_id].to_i
    @expand_contract_crawler_page = CrawlerPage.find_by_id(crawler_page_id)

    case params[:crawler_page_action]
      when "expand-contract"

        expand = params[:expand_contract_radio].to_s == 'true' ? true : false
        if expand
          if DisplayNode.exists?(user_id: current_user.id, crawler_page_id: crawler_page_id) == false and crawler_page_id > 0
            display_node = DisplayNode.new
            display_node.user_id = current_user.id
            display_node.crawler_page_id = crawler_page_id
            display_node.save
            #@display_node = true;
          end
        else
          delete_str = "DELETE FROM display_nodes WHERE user_id = #{current_user.id} AND crawler_page_id = #{crawler_page_id}"
          ActiveRecord::Base.connection.execute(delete_str)
          #@display_node = false;
        end
        descend_ids = @expand_contract_crawler_page.descendant_ids
        if descend_ids == nil
          next_page_id = crawler_page_id +1
        else
          next_page_id = descend_ids.max+1
        end
        if CrawlerRange.exists? == false
          @crawler_page_ranges = []
        else
          @crawler_page_ranges = CrawlerRange.where('user_id = ? and begin_id <= ? and end_id >= ?', current_user.id, next_page_id, crawler_page_id).order('begin_id asc').map { |range| [range.begin_id, range.end_id] }
          if @crawler_page_ranges.length ==0
            @crawler_page_ranges = [[-1, -1]]
          end
        end


      when "page-range"
        crawler_range = CrawlerRange.where(user_id: current_user.id).order('begin_id asc').map { |range| [range.begin_id, range.end_id] }
        descendant_ids = @expand_contract_crawler_page.descendant_ids
        if descendant_ids.length > 0
          begin_id2 = descendant_ids.max + 1
        else
          begin_id2 = crawler_page_id + 1
        end
        logger.info "******* begin_id2 = #{begin_id2}"
        if crawler_range.length == 0
          created_ranges = 0
          begin_id = CrawlerPage.first.id+1
          end_id = crawler_page_id -1
          if begin_id <= end_id
            new_crawler_range1 = CrawlerRange.new
            new_crawler_range1.user_id = current_user.id
            new_crawler_range1.begin_id = begin_id
            new_crawler_range1.end_id = end_id
            new_crawler_range1.save
            logger.info "a new_crawler_range1 = #{new_crawler_range1.inspect}"
            created_ranges = created_ranges +1
          end

          descendant_ids = @expand_contract_crawler_page.descendant_ids

          if descendant_ids.length > 0
            begin_id2 = descendant_ids.max + 1
          else
            begin_id2 = crawler_page_id + 1
          end
          end_id2 = CrawlerPage.last.id
          if begin_id2 <= end_id2
            new_crawler_range2 = CrawlerRange.new
            new_crawler_range2.user_id = current_user.id
            new_crawler_range2.begin_id = begin_id2
            new_crawler_range2.end_id = end_id2
            new_crawler_range2.save
            logger.info "b new_crawler_range2 = #{new_crawler_range2.inspect}"
            created_ranges = created_ranges +1
          end

          if created_ranges == 0 # everything has been deselected
            new_crawler_range = CrawlerRange.new
            new_crawler_range.user_id = current_user.id
            new_crawler_range.begin_id = -1
            new_crawler_range.end_id = -1
            new_crawler_range.save
            logger.info "c new_crawler_range = #{new_crawler_range.inspect}"
          end
          @crawler_page_ranges = [[-1, -1]] # crawler_page and children must be deselected
        else
          if @expand_contract_crawler_page.in_range?(crawler_range)
            logger.info "The db might  have ranges strictly contained in the interval [crawler_page_id, begin_id2]=[#{crawler_page_id},#{begin_id2}]"
            logger.info "These need to be deleted"
            CrawlerRange.where('user_id = ? AND begin_id >= ? AND end_id <= ?', current_user.id, crawler_page_id, begin_id2-1).destroy_all
            delete_str = "DELETE FROM crawler_ranges WHERE user_id = #{current_user.id} AND begin_id >= #{crawler_page_id} AND end_id <= #{begin_id2-1}"
            logger.info "** delete_str = #{delete_str}"
            #ActiveRecord::Base.connection.execute(delete_str)
            created_ranges = 0
            crawler_range = CrawlerRange.where(user_id: current_user.id).order('begin_id asc').map { |range| [range.begin_id, range.end_id] }
            end_id = crawler_range.map { |rr| rr[1] }.bsearch { |e_id| e_id >= begin_id2-1 }

            if end_id
              crawler_range1 = CrawlerRange.where('user_id = ? and end_id = ?', current_user.id, end_id).first
              logger.info "crawler_page_id = #{crawler_page_id}, crawler_range = #{crawler_range1.inspect}"

              logger.info "1 There may still be an interval [begin_id,end_id]=[#{crawler_range1.begin_id},#{crawler_range1.end_id}] which intersects [crawler_page_id, begin_id2-1] = [#{crawler_page_id},#{begin_id2-1}]"
              logger.info "if so, try to budge it to [begin_id2, end_id]=[#{begin_id2},#{end_id}]"
              begin_id1 = begin_id2
              end_id1 = end_id


              #begin_id2 already set
              end_id2 = end_id
              if begin_id1<=end_id1 and crawler_range1.begin_id <= end_id1
                if begin_id2-1 < crawler_range1.end_id and crawler_range1.begin_id < crawler_page_id
                  logger.info "[crawler_page_id, begin_id2-1]  is contained entirely within crawler_range1"
                  logger.info "therefore we also need to create a new interval [#{crawler_range1.begin_id},#{crawler_page_id-1}]"
                  new_crawler_range = CrawlerRange.new
                  new_crawler_range.user_id = current_user.id
                  new_crawler_range.begin_id= crawler_range1.begin_id
                  new_crawler_range.end_id = crawler_page_id-1
                  new_crawler_range.save

                end

                crawler_range1.begin_id = begin_id1
                #crawler_range1.end_id = end_id1
                crawler_range1.save
                created_ranges = created_ranges +1
                logger.info "e new_crawler_range2 = #{crawler_range1.inspect}"
              end
            end
            crawler_rangee = CrawlerRange.where(user_id: current_user.id).order('begin_id asc').map { |range| [range.begin_id, range.end_id] }
            end_id = crawler_rangee.map { |rr| rr[1] }.bsearch { |e_id| e_id >= crawler_page_id }
            if end_id
              crawler_range2 = CrawlerRange.where('user_id = ? and end_id = ?', current_user.id, end_id).first

              logger.info "2 There may still be an interval [begin_id,end_id]=[#{crawler_range2.begin_id},#{crawler_range2.end_id}] which intersects [crawler_page_id, begin_id2-1] = [#{crawler_page_id},#{begin_id2-1}]"
              logger.info "if so, try to budge it to [begin_id, crawler_page_id-1]=[#{crawler_range2.begin_id},#{crawler_page_id-1}]"
              begin_id1 = crawler_range2.begin_id
              end_id1 = crawler_page_id-1


              if begin_id1 <= end_id1 and crawler_range2.begin_id <= end_id1


                crawler_range2.begin_id = begin_id1
                crawler_range2.end_id = end_id1
                crawler_range2.save

                created_ranges = created_ranges +1
                logger.info "d new_crawler_range2 = #{crawler_range2.inspect}"
              end
            end
            if CrawlerRange.exists?(user_id: current_user.id) == false


              new_crawler_range = CrawlerRange.new
              new_crawler_range.user_id = current_user.id
              new_crawler_range.begin_id = -1
              new_crawler_range.end_id = -1
              new_crawler_range.save
              logger.info "f new_crawler_range = #{new_crawler_range.inspect}"
            end


            @crawler_page_ranges = [[-1, -1]] # crawler_page and children must be deselected
          else
            # we want to put the crawler page into a range
            crawler_range = CrawlerRange.where('user_id = ?', current_user.id).order('begin_id asc')
            logger.info "** crawler_range = #{crawler_range.inspect}"
            if crawler_range.length == 1 and crawler_range[0].begin_id == -1 and crawler_range[0].end_id == -1
              begin_id1 = crawler_page_id
              end_id1 = begin_id2 -1
              logger.info "CrawlerPage.first.id = #{CrawlerPage.first.id}, CrawlerPage.last.id = #{CrawlerPage.last.id}"
              if begin_id1 > CrawlerPage.first.id + 1 or end_id1 < CrawlerPage.last.id
                crawler_range[0].begin_id = begin_id1
                crawler_range[0].end_id = end_id1
                crawler_range[0].save
                logger.info "g new_crawler_range = #{crawler_range[0].inspect}"
              else
                CrawlerRange.destroy(crawler_range[0].id)
                logger.info "g2 deleted crawler_range = #{crawler_range[0].inspect}"
              end

            else
              updated_ranges = 0
              delete_rangs = CrawlerRange.where('user_id = ? AND begin_id > ? AND end_id < ?', current_user.id, crawler_page_id, begin_id2-1).destroy_all
              delete_str = "DELETE FROM crawler_ranges WHERE user_id = #{current_user.id} AND begin_id > #{crawler_page_id} AND end_id < #{begin_id2-1}"
              logger.info "** delete_str = #{delete_str}"
              #ActiveRecord::Base.connection.execute(delete_str)
              crawler_range = CrawlerRange.where('user_id = ?', current_user.id).order('begin_id asc')
              previous_index = crawler_range.map { |rr| rr.end_id }.reverse.bsearch_index { |e_id| e_id < crawler_page_id }
              rcrawler_range = crawler_range.reverse
              logger.info "previous index = #{previous_index}, crawler_range = #{crawler_range.map { |rr| rr.end_id }}"


              if previous_index != nil and rcrawler_range[previous_index].end_id+1 == crawler_page_id
                rcrawler_range[previous_index].end_id = begin_id2 -1
                rcrawler_range[previous_index].save
                updated_ranges = updated_ranges + 1
                logger.info "h rcrawler_range[previous_index] = #{rcrawler_range[previous_index].inspect}"
              end
              next_index = crawler_range.map { |rr| rr.begin_id }.bsearch_index { |b_id| b_id >= crawler_page_id }

              logger.info "next_index index = #{next_index}, crawler_range = #{crawler_range.map { |rr| rr.begin_id }}"
              if next_index != nil and crawler_range[next_index].begin_id <= begin_id2
                crawler_range[next_index].begin_id = crawler_page_id
                crawler_range[next_index].save
                updated_ranges = updated_ranges + 1
                logger.info "i crawler_range[next_index] = #{crawler_range[next_index].inspect}"
              end
              if updated_ranges == 2
                rcrawler_range[previous_index].end_id = crawler_range[next_index].end_id
                rcrawler_range[previous_index].save
                logger.info "j rcrawler_range[previous_index] = #{rcrawler_range[previous_index].inspect}, crawler_range[next_index] = #{crawler_range[next_index]}"
                CrawlerRange.destroy(crawler_range[next_index].id)

              end

              if updated_ranges == 0
                new_crawler_range = CrawlerRange.new
                new_crawler_range.user_id = current_user.id
                new_crawler_range.begin_id = crawler_page_id
                new_crawler_range.end_id = begin_id2 -1
                new_crawler_range.save
                logger.info "k new_crawler_range = #{new_crawler_range.inspect}"
              end
              CrawlerRange.where('user_id = ? and begin_id = ? and end_id = ?', current_user.id, CrawlerPage.first.id + 1, CrawlerPage.last.id).destroy_all
            end
            @crawler_page_ranges = [[crawler_page_id, begin_id2-1]] # crawler_page and children must be selected
          end
        end
      else
    end


    logger.info "@expand_contract_crawler_page = #{@expand_contract_crawler_page.inspect}"
    respond_to do |format|
      format.js
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
      when "Analyse Domain"
        analyse_domain(params)
      when "Fix Domain"
        fix_domain(params)
      when "Reorder Pages"
        reorder_pages(params)
      when "Deaccent Domain"
        deaccent_domain(params)
      when "Set Paragraphs"
        set_paragraphs(params)
      when "Move Selected"
        move_domain(params)
      when "Remove Domain"
        remove_domain(params)
      else

    end
    #  logger.info "domain_action result_str = #{@result_str}"
    respond_to do |format|
      format.js
    end
  end

  def analyse_domain(params)
    logger.info "analyse_domain begin"
    flash[:notice] = "analysing domain"
    flow_str = params[:flow_str]
    domain_crawler = DomainCrawler.find_by_id(current_user.current_domain_crawler_id)
    domain_crawler.analyse_domain(current_user.id, flow_str)
    @selected = DOMAIN_ACTION[:analyse_domain]
  end

  def fix_domain(params)
    logger.info "fix_domain begin"
    @result_str = "hello"
    domain_crawler_id = CrawlerPage.find_by_id(params[:domain_radio]).domain_crawler_id;
    domain_crawler = DomainCrawler.find_by_id(domain_crawler_id); 1
    result_str = domain_crawler.fix_domain()

    #   call_rake :fix_domain, :domain_crawler_id => domain_crawler_id
    flash[:notice] = "fixing domain"


    #  logger.info "fix_domain result: #{@result_str}"
    @selected = DOMAIN_ACTION[:fix_domain]
  end
  def deaccent_domain(params)
    logger.info "deaccent_domain begin"
    crawler_page = CrawlerPage.find_by_id(params[:domain_radio])
    domain_crawler_id = crawler_page.domain_crawler_id;
    domain_crawler = DomainCrawler.find_by_id(domain_crawler_id);


    result_str = domain_crawler.deaccent_domain(crawler_page)
    #   call_rake :fix_domain, :domain_crawler_id => domain_crawler_id
    flash[:notice] = "deaccenting domain"
    @selected = DOMAIN_ACTION[:deaccent_domain]
  end
  def deaccent_domain(params)
    logger.info "deaccent_domain begin"
    crawler_page = CrawlerPage.find_by_id(params[:domain_radio])
    domain_crawler_id = crawler_page.domain_crawler_id;
    domain_crawler = DomainCrawler.find_by_id(domain_crawler_id);


    result_str = domain_crawler.deaccent_domain(crawler_page)
    #   call_rake :fix_domain, :domain_crawler_id => domain_crawler_id
    flash[:notice] = "deaccenting domain"
    @selected = DOMAIN_ACTION[:deaccent_domain]
  end
  def reorder_pages(params)
    logger.info "reorder_pages begin parama = #{params}"
    crawler_page = CrawlerPage.find_by_id(params[:domain_radio])
    domain_crawler_id = crawler_page.domain_crawler_id;
    domain_crawler = DomainCrawler.find_by_id(domain_crawler_id);


    if domain_crawler !=nil
    result_str = domain_crawler.reorder_pages(crawler_page)
    end
    #   call_rake :fix_domain, :domain_crawler_id => domain_crawler_id
    flash[:notice] = "reordering pages"
    @selected = DOMAIN_ACTION[:reorder_pages]
  end

  def set_paragraphs(params)
    logger.info "set_paragraphs begin"
    first_null_id = WordSingleton.find_by_sql("SELECT * FROM word_singletons WHERE paragraph_id IS NULL LIMIT 1").first;
    if first_null_id != nil
      last_id = WordSingleton.find_by_sql("SELECT * FROM word_singletons ORDER BY id DESC LIMIT 1").first.id
      first_id = first_null_id.id
      block_size = 1000
      while first_id < last_id
        update_str = "UPDATE word_singletons AS ws SET paragraph_id = s.paragraph_id FROM sentences s WHERE s.id = sentence_id AND ws.id >=  #{first_id} AND ws.id < #{first_id+block_size}"
        ActiveRecord::Base.connection.execute(update_str)
        first_id = first_id+block_size;
      end
    end
    last_id


    flash[:notice] = "setting paragraphs"
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
      old_domain_crawler_id = crawler_page_name.domain_crawler_id
      crawler_page_name.domain_crawler_id = new_parent.domain_crawler_id
      crawler_page_name.save;

      if CrawlerPage.exists?(domain_crawler_id: old_domain_crawler_id) ==false
        if current_user.current_domain_crawler_id = old_domain_crawler_id
          current_user.current_domain_crawler_id = new_parent.domain_crawler_id

          current_user.save
          @domain_crawler = DomainCrawler.find_by_id(new_parent.domain_crawler_id)
          @domain_crawler.crawler_page_id = new_parent.root.id
          @domain_crawler.save


        end
        DomainCrawler.destroy(old_domain_crawler_id)
      end

      @result_str = ""
    end
    #   logger.info "move_domain result_str = #{@result_str}"
    param2 = {:domain_radio=> params[:move_location_domain_radio]}
    reorder_pages(param2)
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
    params.require(:domain_crawler).permit(:user_id, :domain_home_page, :short_name, :description, :filter, :flow_str)
  end
end
