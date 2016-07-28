class SearchQuery < ApplicationRecord
  def search(pages)
    logger.info "SearchQuery search"
    page_hash(pages)
    if self.second_search_term.length == 0
      search_results = single_search(self.first_search_term)
    elsif self.first_search_term.length == 0
      search_results = single_search(self.second_search_term)
    else
      search_results = double_search(self.first_search_term, self.second_search_term)

    end
    return search_results
  end

  def process_sentences(sentence_set, tokens)
    logger.info "process_sentences: tokens: #{tokens}, sentence_set: #{sentence_set}"
    @search_results = [];
    @highlighted_result = "";
    @search_result = nil;
    @last_sentence_id = 0;
    @current_paragraph_id = 0
    sentence_set.each do |sentence_id|
      sentence = Sentence.find_by_id(sentence_id)
      #     logger.info "04"
      paragraph = Paragraph.find_by_id(sentence.paragraph_id)
      #   logger.info "05"
      content = sentence.content.gsub(/\n/, ' ')
      logger.info "content: #{content}"
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
      logger.info "highlights: #{highlights}"
      sorted_highlights = Hash[highlights.sort]

      logger.info "sorted highlights #{sorted_highlights}"
      compressed_highlights = []
      sorted_highlights.each do |a, b|
        if compressed_highlights.length == 0 or a > compressed_highlights[-1][1]
          compressed_highlights << [a, b]
        elsif b > compressed_highlights[-1][1]
          compressed_highlights[-1][1] = b
        end
      end
      compressed_highlights.reverse_each do |pair|
        logger.info "inserting pair #{pair}"
        content.insert(pair[1], '</span>')
        content.insert(pair[0], '<span class="highlight">')
      end
      logger.info "compressed highlights: #{compressed_highlights}"
      logger.info "highlighted content: #{content}"
      if @current_paragraph_id != paragraph.id
        if @search_result != nil
          complete_result()
        end
        @current_paragraph_id = paragraph.id
        @search_result = SearchResult.new
        @search_result.user_id = self.user_id
        @search_result.search_query_id = self.id
        @search_result.sentence_id = sentence.id
        @search_result.crawler_page_id = @result_hash[paragraph.result_page_id]
        @search_result.begin_display_paragraph_id = paragraph.id
        @search_result.end_display_paragraph_id = paragraph.id
      end
      sentence_ids = Sentence.where("paragraph_id = ? and id < ? and id > ?", paragraph.id, sentence.id, @last_sentence_id)
      @last_sentence_id = sentence.id
      sentence_ids.each do |sentence_id|
        sentence = Sentence.find_by_id(sentence_id)
        @highlighted_result << sentence.content << ". "
      end
      @highlighted_result << content << ". "


    end
    if @search_result != nil
      complete_result()
    end
  end

  def get_terms(search_terms)
    term_list = search_terms.split(' OR ')
    term_str = ""
    term_list.each do |term|
      if term.length >0
        if term_str.length >0
          term_str << " OR "
        end
        term_str << "word_name LIKE '#{term}'"
      end

    end
    logger.info "term_str: #{term_str}"
    terms = Word.where(term_str)
    return terms;

  end

  def single_search(search_term)

   # terms = Word.where("word_name LIKE (?)", "#{search_term}")
    terms = get_terms(search_terms)
    logger.info "single_search words = #{terms.inspect}"
    sentence_set = SortedSet.new
    terms.each do |term|
      #   logger.info "01"
      word_singletons = WordSingleton.where(word_id: term.id, result_page_id: @result_pages)
      #   logger.info "02"
      word_singletons.each do |word_singleton|
        #     logger.info "03"
        sentence_set.add(word_singleton.sentence_id)
      end
    end
    tokens = search_term.split(/%| OR /)

    process_sentences(sentence_set, tokens)

    logger.info "search_results: @search_results.inspect"
    return @search_results
  end

  def complete_result
    sentence_ids = Sentence.where("paragraph_id = ? and id > ?", @current_paragraph_id, @last_sentence_id)

    sentence_ids.each do |sentence_id|
      sentence = Sentence.find_by_id(sentence_id)
      @highlighted_result << sentence.content << ". "
      @last_sentence_id = sentence.id
    end
    @search_result.highlighted_result = @highlighted_result
    @search_result.save
    @search_results << @search_result
    logger.info "single search: #{@search_result.inspect}, #{@highlighted_result}"
    @highlighted_result = "";
  end

  def double_search(first_search_term, second_search_term)
    first_terms = get_terms(first_search_term);
    #Word.where("word_name LIKE (?)", "#{first_search_term}")
    second_terms = get_terms(second_search_term);
    #Word.where("word_name LIKE (?)", "#{second_search_term}")
    logger.info "first_search words = #{first_terms.inspect}"
    logger.info "second_search words = #{second_terms.inspect}"
    sentence_set = SortedSet.new
    first_terms.each do |first_term|
      second_terms.each do |second_term|

        word_multiple = first_term.word_prime * second_term.word_prime;
        #   logger.info "01"
        word_pairs = WordPair.where(word_multiple: word_multiple, result_page_id: @result_pages)
        #   logger.info "02"
        word_pairs.each do |word_pair|
          #     logger.info "03"
          sentence_set.add(word_pair.sentence_id)
        end
      end
    end
    tokens = first_search_term.split(/%| OR /)    +  second_search_term.split(/%| OR /)


    process_sentences(sentence_set, tokens)

    logger.info "search_results: @search_results.inspect"
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
    logger.info "page_hash @result_pages: #{@result_pages}"
  end

  def new
    logger.info "SearchQuery new"

  end

  def create(params, current_user)
    logger.info "SearchQuery create"
    self.user_id = current_user.id
    self.first_search_term = params[:word1];
    self.second_search_term = params[:word2];
    self.save
  end

end
