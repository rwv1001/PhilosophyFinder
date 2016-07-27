class SearchQuery < ApplicationRecord
  def search(pages)
    logger.info "SearchQuery search"
    page_hash(pages)
    if self.second_search_term.length == 0
      single_search(self.first_search_term)
    elsif self.first_search_term.length == 0
      single_search(self.second_search_term)
    else
      double_search(self.first_search_term, self.second_search_term)

    end


  end

  def single_search(search_term)
    search_results = [];
    terms = Word.where("word_name LIKE (?)", "#{search_term}")
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
      sentence_set.each do |sentence_id|
        sentence = Sentence.find_by_id(word_singleton.sentence_id)
        #     logger.info "04"
        paragraph = Paragraph.find_by_id(sentence.paragraph_id)
        #   logger.info "05"
        content = sentence.content.gsub(/\n/, ' ')
        highlights = Hash.new

        search_term.split('%').each do |token|
          if token.length >0
            matches =content.to_enum(:scan, token).map { Regexp.last_match }
            matches.each do |match|
              if highlights.key?(match.offset(0)[0]) == false
                highlights[match.offset(0)[0]]= match.offset(0)[1]
              elsif match.offset(0)[1] > highlights[match.offset(0)[0]]
                highlights[match.offset(0)[0]] = match.offset(0)[1]
              end
            end
          end

        end
        sorted_highlights = Hash[highlight.sort]

        compressed_highlights = []
        sorted_highlights.each do |a, b|
          if compressed_highlights.length == 0 or a > compressed_highlights[-1][1]
            compressed_highlights << [a, b]
          elsif b > compressed_highlights[-1][1]
            compressed_highlights[-1][1] = b
          end

          compressed_highlights.reverse_each do |pair|
            content.insert(pair[1], '</span>')
            content.insert(pair[0], '<span class="highlight">')
          end
        end
        search_result = SearchResult.new
        search_result.user_id = self.user_id
        search_result.search_query_id = self.id
        search_result.highlighted_result = content

        search_result.sentence_id = sentence.id
        search_result.crawler_page_id = @result_hash[paragraph.result_page_id]
        search_result.begin_display_paragraph_id = paragraph.id
        search_result.end_display_paragraph_id = paragraph.id
        t.integer :user_id

        search_result.save
        search_results << search_result


        logger.info "single search: #{search_result.inspect}, #{content}"
      end
    end
  end

  def double_search(first_search_term, second_search_term)

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
