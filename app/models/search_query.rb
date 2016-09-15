require 'digest/md5'

class SearchQuery < ApplicationRecord
  def get_search_terms
    search_terms = []
    if self.first_search_term.length !=0
      search_terms << self.first_search_term
    end
    if self.second_search_term.length !=0
      search_terms << self.second_search_term
    end
    if self.third_search_term.length !=0
      search_terms << self.third_search_term
    end
    if self.fourth_search_term.length !=0
      search_terms << self.fourth_search_term
    end
    return search_terms
  end

  def search(pages)
    logger.info "SearchQuery search: #{first_search_term}, #{second_search_term}, #{third_search_term}, #{fourth_search_term}"
    page_hash(pages)

    @truncate_length = -1
    @search_results = []

    search_output = Hash.new
    search_terms = get_search_terms()


    if search_terms.length == 1
      single_search(self.first_search_term)
    elsif search_terms.length > 1
      multiple_search(search_terms)
    end
    search_output[:search_results] = @search_results
    search_output[:unprocessed_sentence_count] =@unprocessed_sentence_count
    search_output[:truncate_length]=@truncate_length


    return search_output
  end

  def initialize_process_sentences()

    @search_results = [];
    @highlighted_result = "";
    @search_result = nil;
    @last_sentence_id = 0;
    @current_paragraph_id = 0
    @unprocessed_sentence_count = 0
    @count = 0
    @quit_processing = false
    if @result_hash == nil
      @result_hash = Hash.new
    end
    if @connection == nil
      @connection = ActiveRecord::Base.connection
    end
  end

  def self.process_more_results(query_id)
    search_query = SearchQuery.find_by_id(query_id)
    process_output = Hash.new
    process_output[:unprocessed_sentence_count] = search_query.process_more
    all_results = SearchResult.where(search_query_id: query_id).order("id asc")
    process_output[:found_results]= all_results.count
    process_output[:absolute_first] = all_results[0].id
    process_output[:absolute_last] = all_results[-1].id
  #  logger.info "process_output: #{process_output.inspect}"
   # logger.info "process_output ids: #{all_results[0].id}, #{all_results[1].id}, #{all_results[2].id}, #{all_results[-1].id}, "
    return process_output

  end

  def self.fetch(query_id, current_index, range)
    fetch_output = Hash.new
    if range >0
      fetch_output[:fetch_results] = SearchResult.where('search_query_id = ? and id > ?', query_id, current_index).limit(range).order('id asc')
    else
      fetch_output[:fetch_results] = SearchResult.where('search_query_id = ? and id < ?', query_id, current_index).limit(-range).order('id desc').reverse
    end


    all_results = SearchResult.where(search_query_id: query_id).order('id asc')
    fetch_output[:unprocessed_sentence_count] = PrelimResult.where(search_query_id: query_id).count
    fetch_output[:found_results]= all_results.count
    if fetch_output[:found_results] >0
      fetch_output[:absolute_first] = all_results[0].id
      fetch_output[:absolute_last] = all_results[-1].id
    else
      fetch_output[:absolute_first] = 0
      fetch_output[:absolute_last] = 0
    end




    return fetch_output


  end

  def self.tidy_up(user_id)
    search_queries = SearchQuery.where(user_id: user_id).order('view_priority desc')
    if search_queries.length > MAX_QUERY_STORE
      delete_priority = search_queries[MAX_QUERY_STORE].view_priority
      del_str1 = "DELETE sr FROM search_results sr INNER JOIN search_queries on search_queries.id = sr.search_query_id
                 WHERE sr.user_id = #{user_id} AND search_queries.view_priority <= #{delete_priority} AND NOT EXISTS (SELECT 1 FROM group_elements
                 WHERE group_elements.search_result_id  = sr.id )"
      del_str1_postgres = "DELETE FROM search_results sr WHERE user_id =  #{user_id} AND (SELECT COUNT(*) FROM search_queries sq where sq.view_priority <= #{delete_priority}  AND sq.id = sr.search_query_id ) >0 AND (SELECT COUNT(*) FROM group_elements WHERE group_elements.search_result_id = sr.id) = 0;
"
      del_str2 = "DELETE FROM search_queries WHERE view_priority <= #{delete_priority} AND NOT EXISTS (SELECT 1 FROM search_results WHERE search_results.search_query_id = search_queries.id)"
   #   logger.info "del_str1_postgres = #{del_str1_postgres}"
    #  logger.info "del_str2 = #{del_str2}"
      if @connection == nil
        @connection = ActiveRecord::Base.connection
      end
      @connection.execute(del_str1_postgres)
      @connection.execute(del_str2)
    end


  end

  def process_more
    prelim_results = PrelimResult.where(search_query_id: self.id).order("id asc")
    delete_ids = []
    if prelim_results.length > 0
      search_terms = get_search_terms()
      tokens = get_all_tokens(search_terms)

      initialize_process_sentences()
      prelim_results.each do |prelim_result|
        if  @quit_processing == false and (@count < MAX_DISPLAY-1 or (@count >= MAX_DISPLAY-1 and Sentence.find_by_id(prelim_result.sentence_id).paragraph_id == @current_paragraph_id))
          process_sentence(prelim_result.sentence_id, tokens)
          delete_ids.push(prelim_result.id)
        else
          if @quit_processing == false
            @quit_processing = true
            complete_result
          end
        end

      end
      if @search_result != nil and @quit_processing == false
        complete_result()
      end



      if delete_ids.length >0

      sql = "DELETE FROM prelim_results WHERE id IN (#{delete_ids.join(', ')})"
      # logger.info "sql = #{sql}"
      @connection.execute(sql)
      end
      unprocessed_sentence_count = PrelimResult.where(search_query_id: self.id).count
    else
      unprocessed_sentence_count = 0
    end
    return unprocessed_sentence_count
  end

  def process_sentence(sentence_id, tokens)


    sentence = Sentence.find_by_id(sentence_id)
    #     logger.info "04"
    paragraph = Paragraph.find_by_id(sentence.paragraph_id)
    #   logger.info "05"
    content = sentence.content.gsub(/\n/, ' ')

  #  logger.info "@count #{@count} content: #{content}"

    highlights = Hash.new

    tokens.each do |token|
      if token.length >0
        matches =content.to_enum(:scan, /#{token}/im).map { Regexp.last_match }
        matches.each do |match|
          if highlights.key?(match.offset(0)[0]) == false
            highlights[match.offset(0)[0]]= match.offset(0)[1]
          elsif match.offset(0)[1] > highlights[match.offset(0)[0]]
            highlights[match.offset(0)[0]] = match.offset(0)[1]
          end
        end
      end

    end
    #  logger.info "highlights: #{highlights}"
    sorted_highlights = Hash[highlights.sort]

    #   logger.info "sorted highlights #{sorted_highlights}"
    compressed_highlights = []
    sorted_highlights.each do |a, b|
      if compressed_highlights.length == 0 or a > compressed_highlights[-1][1]
        compressed_highlights << [a, b]
      elsif b > compressed_highlights[-1][1]
        compressed_highlights[-1][1] = b
      end
    end
    compressed_highlights.reverse_each do |pair|
      #       logger.info "inserting pair #{pair}"
      content.insert(pair[1], '</span>')
      content.insert(pair[0], '<span class="highlight">')
    end
    #  logger.info "compressed highlights: #{compressed_highlights}"
    # logger.info "highlighted content: #{content}"
    if @current_paragraph_id != paragraph.id
      if @search_result != nil
        complete_result()
      else
        logger.info "@search_result is nil"
      end
      @current_paragraph_id = paragraph.id
      @search_result = SearchResult.new
      @search_result.user_id = self.user_id
      @search_result.search_query_id = self.id
      @search_result.sentence_id = sentence.id
      if @result_hash.key?(paragraph.result_page_id) == false
        if CrawlerPage.exists?(result_page_id: paragraph.result_page_id)
          crawler_id = CrawlerPage.where(result_page_id: paragraph.result_page_id).first.id
          @result_hash[paragraph.result_page_id] = crawler_id
        else
          @result_hash[paragraph.result_page_id] = -1
        end
      end
      @search_result.crawler_page_id = @result_hash[paragraph.result_page_id]

      @search_result.begin_display_paragraph_id = paragraph.id
      @search_result.end_display_paragraph_id = paragraph.id
    end
    sentence_ids = Sentence.where("paragraph_id = ? and id < ? and id > ?", paragraph.id, sentence.id, @last_sentence_id).order("id asc")
    @last_sentence_id = sentence.id
    sentence_ids.each do |sentence_id1|
      sentence1 = Sentence.find_by_id(sentence_id1)
      @highlighted_result << sentence1.content << ". "
    end
    @highlighted_result << content << ". "
  end

  def process_sentences(sentence_set, tokens)
    initialize_process_sentences()

    sentence_inserts = []
    if sentence_set == nil
      logger.info "sentence_set is nil"
      return
    end
    if sentence_set.empty?
      logger.info "sentence_set is empty"
      return
    end
  #  logger.info "process_sentences: tokens: #{tokens}, sentence_set: #{sentence_set.length}"

    sentence_set.each do |sentence_id|
      if @quit_processing == false and (@count < MAX_DISPLAY-1 or (@count >= MAX_DISPLAY-1 and Sentence.find_by_id(sentence_id).paragraph_id == @current_paragraph_id))
        process_sentence(sentence_id, tokens)
      else
        if @quit_processing == false
          @quit_processing = true
          complete_result
        end

        sentence_inserts.push "(#{self.id}, #{sentence_id})"
      end
    end
    @unprocessed_sentence_count = sentence_inserts.length
    if sentence_inserts.length > 0

      sql = "INSERT INTO prelim_results (search_query_id, sentence_id) VALUES #{sentence_inserts.join(', ')}"
      # logger.info "sql = #{sql}"
      @connection.execute(sql)
    end

    if @search_result != nil and @quit_processing == false
      complete_result()
   end
  end


  def get_terms(search_terms)
    term_list = search_terms.split(' OR ')
    term_str = ""
    term_list.each do |term|
      term = term.gsub(/(^\s*|\s*$)/, "")
      if term.length >0
        if term_str.length >0
          term_str << " OR "
        end
        term_str << "word_name ILIKE '#{term}'"
      end

    end
   logger.info "term_str: #{term_str}"
    terms = Word.where(term_str)
    return terms;

  end

  def single_search(search_term)
    logger.info "single_search begin"

    # terms = Word.where("word_name LIKE (?)", "#{search_term}")
    terms = get_terms(search_term)
  #  logger.info "single_search words = #{terms.inspect}"
    sentence_set = SortedSet.new
    terms.each do |term|
      #   logger.info "01"
      word_singletons = WordSingleton.where(word_id: term.id_value, result_page_id: @result_pages).order("id asc")
      #   logger.info "02"
      word_singletons.each do |word_singleton|
        #     logger.info "03"
        sentence_set.add(word_singleton.sentence_id)
      end
    end
    tokens = get_tokens(search_term)

    sentence_set = truncate(sentence_set.to_a)
    process_sentences(sentence_set, tokens)

 #   logger.info "search_results: @search_results.length"
    return @search_results
  end

  def get_tokens(search_term)
    or_list = search_term.split(/ OR /)
    tokens = []

    or_list.each do |or_item|
      or_item = or_item.gsub(/(^\s*|\s*$)/, "") # " hello " -> "hello"
      if or_item[0]=="%"
        or_item[0]=""
        or_item.insert(0, "\\b\\w*")
     #   logger.info "a #{or_item}"
      else
        or_item.insert(0, "\\b")
    #    logger.info "b #{or_item}"
      end
      if or_item[-1]=="%"
        or_item[-1]=""
        or_item.insert(-1, "\\w*\\b")
   #     logger.info "c #{or_item}"
      else
        or_item.insert(-1, "\\b")
   #     logger.info "d #{or_item}"
      end
      or_item = or_item.gsub("%", "\\w*")
   #   logger.info "e #{or_item}"
      tokens << or_item
    end
 #   logger.info "get_tokens, search_term: #{search_term}"
 #   logger.info "get_tokens, tokens: #{tokens}"
    return tokens

  end

  def complete_result
    sentence_ids = Sentence.where("paragraph_id = ? and id > ?", @current_paragraph_id, @last_sentence_id).order("id asc")

    sentence_ids.each do |sentence_id|
      sentence = Sentence.find_by_id(sentence_id)
      @highlighted_result << sentence.content << ". "
      @last_sentence_id = sentence.id
    end
    @search_result.highlighted_result = @highlighted_result

    hash_value = Digest::MD5.hexdigest(@highlighted_result)
    if SearchResult.exists?(search_query_id: self.id, hash_value: hash_value)== false
      @search_result.hash_value = hash_value
      @search_result.save
      @count = @count +1
      @search_results << @search_result
    else
      logger.info "result already exists - set to @search_result to nil"
      @search_result= nil
    end
#    logger.info "single search: #{@search_result.inspect}, #{@highlighted_result}"
    @highlighted_result = "";
  end

  def get_all_tokens(search_terms)
    tokens = []
    search_terms.each do |search_term|
      tokens.concat(get_tokens(search_term))
    end
    return tokens
  end

  def truncate(sentence_set)
    if sentence_set.length == 0
      return sentence_set
    end
    sql_str = "SELECT par.id, max(sen.id) as max_sen_id FROM paragraphs par INNER JOIN sentences sen ON sen.paragraph_id = par.id WHERE sen.id IN  (#{sentence_set.to_a.join(', ')})  GROUP BY par.id ORDER BY par.id ASC;"

  #  logger.info("TRUNCATE QUERY: #{sql_str}")
    paragraphs = Paragraph.find_by_sql(sql_str)
 #   logger.info("paragraphs length = #{paragraphs.length}")
    if paragraphs.length > MAX_RESULTS
      @truncate_length = paragraphs.length
      max_par = paragraphs[MAX_RESULTS-1]
      max_sen = max_par.max_sen_id
      ind = 0
      while sentence_set[ind]<=max_sen and ind < sentence_set.length
        ind = ind +1
      end
 #     logger.info "max_par.id = #{max_par.id}, max_sen = #{max_sen}, sentence_set[ind-1] = #{sentence_set[ind-1]}, ind = #{ind}"
      return sentence_set = sentence_set[0..(ind-1)]



    else
      return sentence_set
    end

  end


  def multiple_search(search_terms)
    logger.info "multiple_search begin"
    terms = []


    search_terms.each do |search_term|
      terms << get_terms(search_term)
    end
    tokens = get_all_tokens(search_terms)

    term_indicies = (0..search_terms.length-1).to_a
    term_pairs=term_indicies.combination(2).to_a
  #  logger.info "term_pairs: #{term_pairs.inspect}"
    result_pair_str = "(#{@result_pages.join(', ')})"
    sql_str = []
    sentence_pairs = []
    sql_intersect_header = ""
    term_pairs.each do |term_pair|
      word_multiples = []
      terms[term_pair[0]].each do |first_term|
        terms[term_pair[1]].each do |second_term|
          word_multiples << first_term.word_prime * second_term.word_prime
        end
      end
      if word_multiples.length > 0
        sql_str = "SELECT * FROM word_pairs WHERE result_page_id IN  #{result_pair_str} AND separation <= #{self.word_separation} AND word_multiple IN  (#{word_multiples.join(', ')})"
    #    logger.info "sql_str = #{sql_str}"
        word_pairs= WordPair.find_by_sql(sql_str)
        sentence_pair = SortedSet.new
        word_pairs.each do |word_pair|
          sentence_pair.add(word_pair.sentence_id)
        end
        sentence_pairs << sentence_pair
      end
    end
    sentence_set = sentence_pairs.inject(:&).to_a

    sentence_set= truncate(sentence_set)




    process_sentences(sentence_set, tokens)

  #  logger.info "search_results: @search_results.length"
    return @search_results

  end

  def double_search(first_search_term, second_search_term)
    first_terms = get_terms(first_search_term);
    #Word.where("word_name LIKE (?)", "#{first_search_term}")
    second_terms = get_terms(second_search_term);
    #Word.where("word_name LIKE (?)", "#{second_search_term}")
  #  logger.info "first_search words = #{first_terms.inspect}"
   # logger.info "second_search words = #{second_terms.inspect}"
    sentence_set = SortedSet.new
    first_terms.each do |first_term|
      second_terms.each do |second_term|

        word_multiple = first_term.word_prime * second_term.word_prime;
    #    logger.info "word_separation: #{word_separation}, word_multiple: #{word_multiple}"
        word_pairs = WordPair.where("word_multiple = ? and result_page_id = ? and separation <= ?", word_multiple, @result_pages, self.word_separation).order("id asc")
       # word_pairs = WordPair.where(word_multiple: word_multiple, result_page_id: @result_pages)
        #   logger.info "02"
        word_pairs.each do |word_pair|
          #     logger.info "03"
          sentence_set.add(word_pair.sentence_id)
        end
      end
    end
    tokens = first_search_term.split(/%| OR /) + second_search_term.split(/%| OR /)


    process_sentences(sentence_set, tokens)

   # logger.info "search_results: @search_results.length"
    return @search_results
  end

  def page_hash(pages)
    crawler_pages = CrawlerPage.where(id: pages)
    @result_pages = [];
    @result_hash=Hash.new
    crawler_pages.each do |crawler_page|
      @result_pages << crawler_page.result_page_id
      @result_hash[crawler_page.result_page_id] = crawler_page.id
    end
#    logger.info "page_hash @result_pages: #{@result_pages}"
  end

  def new
    logger.info "SearchQuery new"

  end

  def create(params, current_user)
    logger.info "SearchQuery create"

    self.user_id = current_user.id
    search_terms=[]
    if params[:word1].length >0
      search_terms << params[:word1]
    end
    if params[:word2].length >0
      search_terms << params[:word2]
    end
    if params[:word3].length >0
      search_terms << params[:word3]
    end
    if params[:word4].length >0
      search_terms << params[:word4]
    end
    search_terms << "" << "" << "" << ""
    logger.info "SearchQuery create search_terms: #{search_terms}"
    self.first_search_term = search_terms[0];
    self.second_search_term = search_terms[1];
    self.third_search_term = search_terms[2];
    self.fourth_search_term = search_terms[3];
    self.word_separation = params[:word_separation];
    if SearchQuery.exists?(user_id: current_user)
      z =
      logger.info "z =#{z.inspect}"
      self.view_priority = SearchQuery.where(user_id: current_user).maximum('view_priority')+1
    else
      self.view_priority = 1
    end
  #  logger.info "self.view_priority = #{self.view_priority}"
    self.save
  end

end
