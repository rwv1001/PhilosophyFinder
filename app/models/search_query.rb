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

    case self.word_separation
      when SENTENCE_SEPARATION
        sentence_search(search_terms)
      when PARAGRAPH_SEPARATION
        paragraph_search(search_terms)
      else
          multiple_search(search_terms)
       end
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
    @highlighted_result << '<span class="highlight-sentence">' << content << ". " << "</span>"
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
    phrases = []
    terms_hash = Hash.new
    term_list.each do |term|
      term = term.gsub(/(^\s*|\s*$)/, "")
      if term.length >0
        phrase_split = term.split(' ')
        if phrase_split.length == 1
          if term_str.length >0
            term_str << " OR "
          end
          term_str << "word_name ILIKE '#{term}'"
        else
          phrase = []
          phrase_split.each do |phrase_word|
            if phrase.length == 0 or phrase[-1].length !=0

              phrase << Word.where("word_name ILIKE '#{phrase_word}'");
            else
              #Supose we have a phrase of the form 'on ioj% first'. After processing ioj% we know we aren't going to get a match
            end
          end
          #Supose we have a phrase of the form 'on ioj% first'...
          if phrase.length > 0 and phrase[-1].length !=0
            phrases << phrase
          end
        end
      end

    end
    logger.info "term_str: #{term_str}"
    if term_str.length >0
      terms = Word.where(term_str)
    else
      terms = []
    end
    terms_hash[:single_terms]= terms
    terms_hash[:phrases]=phrases
    logger.info "get_terms inspect = #{terms_hash.inspect}"
    return terms_hash;

  end

  def get_phrase_sentence_ids(phrases)

  end
  def get_phrase_multiples(phrases)
    logger.info "get_phrase_multiples: #{phrases.inspect}"
      phrases_multiples =[]  #phrase_multiples=[word1word2multiples, word2word3multiples, ...]
    phrases.each do |phrase|
      phrase_multiples = []
      for i in 0..phrase.length-2
        word_multiples = []
        phrase[i].each do |wild_word_1|
          phrase[i+1].each do |wild_word_2|
            word_multiples << wild_word_1.word_prime * wild_word_2.word_prime
            # logger.info "wild_word_1 = #{wild_word_1.inspect}, wild_word_2 = #{wild_word_2.inspect}"
          end
        end
        phrase_multiples <<  word_multiples
      end
      phrases_multiples << phrase_multiples
      end
      return phrases_multiples
    end

  def single_search(search_term)
    logger.info "single_search begin"

    # terms = Word.where("word_name LIKE (?)", "#{search_term}")
    terms_hash = get_terms(search_term)
    terms = terms_hash[:single_terms]
    logger.info "single_search words = #{terms.inspect}"
    sentence_set = SortedSet.new
    terms.each do |term|
      #   logger.info "01"
      # word_singletons = WordSingleton.where(word_id: term.id_value, result_page_id: @result_pages).order("id asc")
      word_singletons = WordSingleton.where(word_id: term.id_value).order("id asc")
      #   logger.info "02"
      word_singletons.each do |word_singleton|
        #     logger.info "03"
        sentence_set.add(word_singleton.sentence_id)
      end
    end
    phrases = terms_hash[:phrases]
    phrases_multiples = phrases.map { |phrase| get_phrase_multiples(phrase) }


    # sql_str= "SELECT * FROM word_pairs wp1 INNER JOIN word_pairs wp2 ON wp2.sentence_id = wp1.sentence_id INNER JOIN word_pairs wp3 ON  wp3.sentence_id = wp1.sentence_id
    #WHERE wp1.separtion =1 AND  wp2.separtion =1  wp3.separtion =1 AND wp1.word_mulitple IN (#{word_multiples.to_a.join(', ')}) "

    sql_str = "SELECT * FROM word_pairs wp "
    for i in 0..phrases_multiples.length-1
      for j in 0..phrases_multiples[i].length - 1
        sql_str << "INNER JOIN word_pairs wp#{i}_#{j} ON wp#{i}_#{j}.sentence_id = wp.sentence_id "
      end
      sql_str << " WHERE ("
      sql_str << (0..(phrase_multiples.length-1)).to_a.map { |i| (0..(phrase_multiples[i].length-1)).to_a.map {
        "wp#{i}_#{j}.separation = 1 AND wp#{i}_#{j}.word_multiple IN (#{phrase_multiples[i][j].to_a.join(', ')}) " }.join(' AND ') }.join(') OR (')<< ")"

      logger.info "**************** sql_str = #{ sql_str } "
      word_phrase_sentences = WordPair.find_by_sql(sql_str)
      logger.info "word_phrase_sentences = #{word_phrase_sentences.inspect}"
      word_phrase_sentences.map { |sentence| sentence_set.add(sentence.sentence_id) }
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

  def sentence_search(search_terms)
    logger.info "sentence_search begin"
    terms = []
  end

  def paragraph_search(search_terms)
    logger.info "paragraph_search begin"
    terms = []
  end



  def get_multiples_sql_str(multiples_list, separation)
    sql_str = "SELECT * FROM word_pairs wp0 "
    for i in 1..multiples_list.length-1
      sql_str << "INNER JOIN word_pairs wp#{i} ON wp#{i}.sentence_id = wp0.sentence_id "
    end
    sql_str << " WHERE "
    sql_str << (0..(multiples_list.length-1)).to_a.map{|i| "wp#{i}.separation <=#{separation} AND wp#{i}.word_multiple IN (#{multiples_list[i].to_a.join(', ')}) "}.join(' AND ')
    return sql_str
  end


  def multiple_search(search_terms)
    logger.info "multiple_search begin"
    zero_multiples = false
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
    indexed_phrase_multiples=  []
    wml = [] # this is the main multiple structure*************************
    sql_intersect_header = ""
    indexed_phrase_multiples = term_indicies.map { |term_index|  get_phrase_multiples(terms[term_index][:phrases]) }
    logger.info "indexed_phrase_multiples = #{indexed_phrase_multiples.inspect}"
    logger.info "term_indicies = #{term_indicies.inspect}"
    term_pairs.each do |term_pair|
      word_multiples_pair_list = []
      if !zero_multiples
        #******************* term x term multiples **************************
        inter_term_multiples = []
        terms[term_pair[0]][:single_terms].each do |first_term|
          terms[term_pair[1]][:single_terms].each do |second_term|
            inter_term_multiples << first_term.word_prime * second_term.word_prime
          end
        end
        if inter_term_multiples.length > 0
          word_multiples_pair_list << [inter_term_multiples, []]
        end
        #******************* term x phrase multiples **************************
        inter_term_multiples = []
        phrase_multiples =[] #[first_term*]
        phrases = terms[term_pair[1]][:phrases]
        terms[term_pair[0]][:single_terms].each do |first_term|
          phrases.each do |phrase|
            phrase[0].each do |wild_word_2|
              inter_term_multiples << first_term.word_prime * wild_word_2.word_prime
            end
            phrase[-1].each do |wild_word_2|
              inter_term_multiples << first_term.word_prime * wild_word_2.word_prime
            end
          end
        end
        phrase_multiples = indexed_phrase_multiples[term_pair[1]]
        if inter_term_multiples.length>0 && phrase_multiples.length >0
          word_multiples_pair_list << [inter_term_multiples, [phrase_multiples]]
        end
        #******************* phrase x term multiples **************************
        inter_term_multiples = []
        phrase_multiples =[] #[first_term*]
        phrases = terms[term_pair[0]][:phrases]
        terms[term_pair[1]][:single_terms].each do |first_term|
          phrases.each do |phrase|
            phrase[0].each do |wild_word_2|
              inter_term_multiples << first_term.word_prime * wild_word_2.word_prime
            end
            phrase[-1].each do |wild_word_2|
              inter_term_multiples << first_term.word_prime * wild_word_2.word_prime
            end
          end
        end
        phrase_multiples = indexed_phrase_multiples[term_pair[0]]
        if inter_term_multiples.length>0 && phrase_multiples.length >0
          word_multiples_pair_list << [inter_term_multiples, [phrase_multiples]]
        end
        #******************* phrase x phrase multiples **************************
        inter_term_multiples = []
        phrase_multiples =[] #[first_term*]
        phrases0 = terms[term_pair[0]][:phrases]
        phrases1 = terms[term_pair[1]][:phrases]
        phrases0.each do |phrase0|
          phrases1.each do |phrase1|
            phrase0[0].each do |wild_word_1|
              phrase1[-1].each do |wild_word_2|
                inter_term_multiples << wild_word_1.word_prime * wild_word_2.word_prime
              end
            end
            phrase0[-1].each do |wild_word_1|
              phrase1[0].each do |wild_word_2|
                inter_term_multiples << wild_word_1.word_prime * wild_word_2.word_prime
              end
            end
          end
        end
        phrase_multiples0 = indexed_phrase_multiples[term_pair[0]]
        phrase_multiples1 = indexed_phrase_multiples[term_pair[1]]

        if inter_term_multiples.length>0 && phrase_multiples0.length >0 && phrase_multiples1.length > 0
          word_multiples_pair_list << [inter_term_multiples, [phrase_multiples0, phrase_multiples1]]
        end

        if word_multiples_pair_list.length >0
          wml << word_multiples_pair_list

        else
          zero_multiples = true
        end
      end

    end
    #word_multiples_list = [word_multiples_pair_list, (and) word_multiples_pair_list, (and) word_multiples_pair_list, ...]
    #word_multiples_pair_list = [[inter_term_multiples, (and) phrase_multiples], or [inter_term_multiples, and phrase_multiples], or [inter_term_multiples, and phrase_multiples], ...]
    logger.info "wml = #{wml.inspect}"

    sentence_set = SortedSet.new
    if wml.length>0 and !zero_multiples
      sql_str = "SELECT DISTINCT wp.sentence_id FROM word_pairs wp "
      for kk in 0..wml.length-1
        word_multiples_pair_list = wml[kk]
        inter_term_multiples = word_multiples_pair_list[0]


##word_multiples_pair_list << [inter_term_multiples, [phrase_multiples_f,                      phrase_multiples_s]]
#(wp, wp, ...),       [phrase,                  phrase, ...],                  [phrase, phrase, ...]]
#                     [(wp,wp,..),(wp,wp,...)]
        for ii in 0..wml[kk].length-1 #
          sql_str << "INNER JOIN word_pairs wp#{kk}_#{ii} ON wp#{kk}_#{ii}.sentence_id = wp.sentence_id " #k indexes term_pairs, i indexes word_multiples_pair_list (inter_term multiples)
          if wml[kk][ii][1].length >0
            phrase_multiples_f = wml[kk][ii][1][0]
            for jj in 0..wml[kk][ii][1][0].length - 1
              for mm in 0..phrase_multiples_f[jj].length - 1
              sql_str << "INNER JOIN word_pairs wpf#{kk}_#{ii}_#{jj}_#{mm} ON wpf#{kk}_#{ii}_#{jj}_#{mm}.sentence_id = wp.sentence_id "
                end
            end
            if wml[kk][ii][1].length >1
              phrase_multiples_s = wml[kk][ii][1][1]
              for jj in 0..phrase_multiples_s.length - 1
                for mm in 0..phrase_multiples_s[jj].length - 1
                  sql_str << "INNER JOIN word_pairs wps#{kk}_#{ii}_#{jj}_#{mm} ON wps#{kk}_#{ii}_#{jj}_#{mm}.sentence_id = wp.sentence_id "
                end
              end
            end
          end
        end
      end


      sql_str_array =  (0..(wml.length-1)).to_a.map {\
         |kk| (0..(wml[kk].length-1)).to_a.map {\
           |ii| ["SELECT DISTINCT wp#{kk}_#{ii}.sentence_id FROM word_pairs wp#{kk}_#{ii}\
 WHERE wp#{kk}_#{ii}.separation <= #{self.word_separation} AND wp#{kk}_#{ii}.word_multiple IN (#{wml[kk][ii][0].join(', ')}) ", ((wml[kk][ii][1].length>0) ?\
              (0..(wml[kk][ii][1][0].length-1)).to_a.map {|jj|
                     "SELECT DISTINCT wp.sentence_id FROM word_pairs wp " << (0..(wml[kk][ii][1][0][jj].length-1)).to_a.map {|mm|
                       "INNER JOIN word_pairs wpf#{kk}_#{ii}_#{jj}_#{mm} ON wpf#{kk}_#{ii}_#{jj}_#{mm}.sentence_id = wp.sentence_id "}.join(' ')<< "WHERE " << (0..(wml[kk][ii][1][0][jj].length-1)).to_a.map {|mm|\
 "wpf#{kk}_#{ii}_#{jj}_#{mm}.separation = 1 AND wpf#{kk}_#{ii}_#{jj}_#{mm}.word_multiple IN (#{wml[kk][ii][1][0][jj][mm].join(', ')})"}.join(' AND ')} :[]),((wml[kk][ii][1].length>1) ? \
 (0..(wml[kk][ii][1][1].length-1)).to_a.map {|jj|
        "SELECT DISTINCT wp.sentence_id FROM word_pairs wp " << (0..(wml[kk][ii][1][1][jj].length-1)).to_a.map {|mm|
          "INNER JOIN word_pairs wps#{kk}_#{ii}_#{jj}_#{mm} ON wps#{kk}_#{ii}_#{jj}_#{mm}.sentence_id = wp.sentence_id "}.join(' ')<< "WHERE " << (0..(wml[kk][ii][1][1][jj].length-1)).to_a.map {|mm|\
 "wps#{kk}_#{ii}_#{jj}_#{mm}.separation = 1 AND wps#{kk}_#{ii}_#{jj}_#{mm}.word_multiple IN (#{wml[kk][ii][1][1][jj][mm].join(', ')})"}.join(' AND ')} :[])] }}

      sql_str_array.each do |kk|
        (0..kk.length - 1).each.each do |ii|
          (0..kk[ii].length - 1).each do |aa|
          logger.info "kk[ii=#{ii}][#{aa}]  = #{kk[ii][aa].inspect}"
          end
        end
      end

      logger.info " sql_str_array = #{sql_str_array.inspect}"
      sentence_set_1 = sql_str_array.map{|kk| kk.map{|ii|
        if ii[1][0]==nil and ii[2][0]==nil
        WordPair.find_by_sql(ii[0]).map{|wp| wp.sentence_id}.to_set
        else
          if ii[1][0]!=nil
            if ii[2][0]==nil
              WordPair.find_by_sql(ii[0]).map{|wp| wp.sentence_id}.to_set & (ii[1].map{|jj| WordPair.find_by_sql(jj).map{|wp| wp.sentence_id}.to_set}.inject(:|))
            else
              WordPair.find_by_sql(ii[0]).map{|wp| wp.sentence_id}.to_set & (ii[1].map{|jj| WordPair.find_by_sql(jj).map{|wp| wp.sentence_id}.to_set}.inject(:|))\
            & (ii[2].map{|jj| WordPair.find_by_sql(jj).map{|wp| wp.sentence_id}.to_set}.inject(:|))
            end
          elsif ii[2][0]!=nil
            WordPair.find_by_sql(ii[0]).map{|wp| wp.sentence_id}.to_set & (ii[2].map{|jj| WordPair.find_by_sql(jj).map{|wp| wp.sentence_id}.to_set}.inject(:|))
          end

        end
      }.inject(:|)}
      sentence_set = sentence_set_1.inject(:&)

      logger.info "****************** sentence_set= #{sentence_set.inspect}"


      sql_str_array.each do |kk|
        logger.info "kk = #{kk.inspect}"
      end

      sentence_set_array = []

      sentence_set_array << sql_str_array.map { |kk| kk.map{ |ii|
        if ii[1][0]==nil and ii[2][0]==nil
          "sql: #{ii[0]} result =(#{WordPair.find_by_sql(ii[0]).map { |wp| wp.sentence_id }.inspect});"
        else

          if ii[1][0]!=nil
            if ii[2][0]==nil
            "sql: #{ii[0]} result =(#{WordPair.find_by_sql(ii[0]).map { |wp| wp.sentence_id }.inspect}); " \
              << ii[1].map { |jj| "sql: #{jj}, result = #{WordPair.find_by_sql(jj).map { |wp| wp.sentence_id }.inspect}" }.join(" ")
            else
              "sql: #{ii[0]} result =(#{WordPair.find_by_sql(ii[0]).map { |wp| wp.sentence_id }.inspect}); " << ii[1].map { |jj| "sql: #{jj}, result = #{WordPair.find_by_sql(jj).map { |wp| wp.sentence_id }.inspect}" }.join(" ")\
              << ii[2].map { |jj| "sql: #{jj}, result = #{WordPair.find_by_sql(jj).map { |wp| wp.sentence_id }.inspect}" }.join(" ")

            end
        elsif ii[2][0]!=nil
          "sql: #{ii[0]} result =(#{WordPair.find_by_sql(ii[0]).map { |wp| wp.sentence_id }.inspect}); " \
              << ii[2].map { |jj| "sql: #{jj}, result = #{WordPair.find_by_sql(jj).map { |wp| wp.sentence_id }.inspect}" }.join(" ")

          end
        end }}

      logger.info "***********************************************sentence_set_array = #{sentence_set_array.inspect}"











      sentence_set= truncate(sentence_set)
      end
      process_sentences(sentence_set, tokens)
      #  logger.info "search_results: @search_results.length"
      return @search_results

  end

  def double_search(first_search_term, second_search_term)
    first_terms = get_terms(first_search_term)[:single_terms];
    #Word.where("word_name LIKE (?)", "#{first_search_term}")
    second_terms = get_terms(second_search_term)[:single_terms];
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
    crawler_pages = CrawlerPage.all
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
    if params[:word1].length >0 && params[:word1] !~ /^\s*$/
      search_terms << params[:word1]
    end
    if params[:word2].length >0 && params[:word2] !~ /^\s*$/
      search_terms << params[:word2]
    end
    if params[:word3].length >0 && params[:word3] !~ /^\s*$/
      search_terms << params[:word3]
    end
    if params[:word4].length >0 && params[:word4] !~ /^\s*$/
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
