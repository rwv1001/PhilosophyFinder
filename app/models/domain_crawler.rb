require 'nokogiri'
require 'open-uri'
require 'digest/md5'
require 'prime'


class DomainCrawler < ApplicationRecord
  has_many :crawler_pages, :dependent => :destroy
  belongs_to :crawler_page
  @previous_time =0
  @@primes = Prime.instance

  def TimeLogger(str)

    if @previous_time == 0

      @previous_time = Time.now

    else

      time_now = Time.now

      interval = time_now - @previous_time

      @previous_time = time_now

      logger.info "#{@a} Time: #{interval}, #{str} "

      @a=@a+1
    end

  end

  def GetNextPrime(n)
    if n%2 == 0
      possible_prime = n+1
    else
      possible_prime = n+2
    end
    if @@primes == nil
      @@primes = Prime.instance
    end

    while @@primes.prime?(possible_prime) == false
      possible_prime = possible_prime + 2
      #       logger.info "v8"
    end
    return possible_prime

  end

  def sql_save(sql_str)

    @connection.execute(sql_str)
    save_sql = SaveMySql.new
    save_sql.save_str = sql_str[0..1000]
    save_sql.save
  end

  def AddSentencesAndWords()
    logger.info "AddSentencesAndWords begin"
   # logger.info "rwv1001 g"
    if Sentence.exists?
      max_id = Sentence.maximum('id')
   #   logger.info "rwv1001 h"
    else
      max_id = 0
      logger.info "No sentences exist"
    end
    if @sentence_inserts.length >0
   #   logger.info "rwv1001 i"
      sql = %Q"INSERT INTO sentences (content, paragraph_id) VALUES #{@sentence_inserts.to_a.join(', ')}"
      sql_save(sql)
     # logger.info "rwv1001 j"

    else
      logger.info "@sentence_inserts is empty"
    end
    @sentence_objects = Sentence.where("id > #{max_id}").order("id asc")

    if @word_entries.length > 0

      #sql = "INSERT IGNORE INTO words (word_name, id_value, word_prime) VALUES #{@word_entries.to_a.join(', ')}"
      sql = "INSERT INTO words (word_name, id_value, word_prime) VALUES #{@word_entries.to_a.join(', ')}"
      #logger.info "sql = #{sql}"
      sql_save(sql)
    #  logger.info "rwv1001 k"
      if Word.where('id_value >-1').limit(1).length >0
      #  logger.info "rwv1001 l"
        max_prime = Word.maximum('word_prime')
        max_id = Word.maximum('id_value')
     #   logger.info "rwv1001 m"
       # logger.info "max_prime = #{max_prime}, max_id = #{max_id} "
      else
        max_id = 0
        max_prime = 2
      end

      new_words = Word.where(id_value: 0)
      new_id = max_id + 1
      new_prime = GetNextPrime(max_prime)


      new_words_str = []
      new_words.each do |new_word|
        new_words_str << "(\'#{new_word.word_name}\',#{new_id}, #{new_prime})"
        new_prime = GetNextPrime(new_prime)
        new_id = new_id + 1
      end
      if new_words.length > 0

        #sql = "REPLACE INTO words (word_name, id_value, word_prime) VALUES #{new_words_str.to_a.join(', ')}"


        sql = "UPDATE words AS w SET id_value = c.id_value, word_prime= c.word_prime FROM (VALUES  #{new_words_str.to_a.join(', ')}) as c(word_name, id_value, word_prime)
        where c.word_name = w.word_name;"
       # logger.info "sql = #{sql}"
     #   logger.info "rwv1001 o"
        sql_save(sql)
     #   logger.info "rwv1001 v"
      else
        logger.info "new_words is empty"
      end

      new_word_list = "(#{@word_set.to_a.join(', ')})"
      new_words_from_db_str = "word_name IN #{new_word_list}"
      #     logger.info "new_words_from_db_str = #{new_words_from_db_str}"
      new_words_from_db = Word.where("word_name IN #{new_word_list}")
      new_words_from_db.each do |new_word_from_db|
        @word_hash[new_word_from_db.word_name] = new_word_from_db.id_value
        @word_prime_hash[new_word_from_db.word_name] = new_word_from_db.word_prime

      end
    end
  end

  def ProcessSentences(par_sentences, result_page_id)

    @sentence_inserts = []
    @word_inserts = Set.new
    @word_singleton_inserts = []
    @word_pairs_inserts = []
    @word_set = Set.new
    @word_hash = Hash.new
    @word_prime_hash = Hash.new
    @word_entries = Set.new

    @sentence_objects = nil

    par_sentences.each do |par_sentence|

      par_sentence[:sentences].each do |sentence|
        ProcessSentence(sentence, par_sentence[:paragraph_id])
      end
    end

    AddSentencesAndWords()

    @sentence_objects.each do |sentence_obj|
      ProcessSingletonPairs(sentence_obj, result_page_id)
    end
    AddSingletonPairs()
  end


  def AddSingletonPairs()
    logger.info "AddSingletonPairs"
    if @word_singleton_inserts.length > 0
      sql = "INSERT INTO word_singletons (word_id, sentence_id, result_page_id, paragraph_id) VALUES #{@word_singleton_inserts.join(', ')}"
      # logger.info "sql = #{sql}"
      sql_save(sql)
    else
      logger.info "@word_singleton_inserts is empty"
    end
    if @word_pairs_inserts.length > 0
      sql = "INSERT INTO word_pairs (word_multiple, separation, result_page_id,sentence_id) VALUES #{@word_pairs_inserts.join(', ')}"
      # logger.info "sql = #{sql}"
      sql_save(sql)
    else
      logger.info "@word_pairs_inserts is empty"
    end


  end


  def ProcessSentence(sentence, paragraph_id)
    #@sentence_inserts.push "(\"#{sentence.gsub('"', '\"')}\",#{paragraph_id})"
    @sentence_inserts.push "(\'#{sentence.gsub("'","''")}\',#{paragraph_id})" # psql

    sentence = sentence.gsub(/[^a-zA-Z]/, ' ')
    word_list = sentence.split(' ')

    word_list.each do |word|
      # logger.info "#{word_count}, Word: #{word}"

      #   logger.info "v2"
      if word.length > 0
        #      logger.info "v3"
        @word_entries.add "(\'#{word.downcase}\', 0, 0)"
        @word_set.add("\'#{word.downcase}\'")
      end
      #  logger.info "v14"
    end
  end

  def ProcessSingletonPairs(sentence_obj, result_page_id)

    sentence = sentence_obj.content.gsub(/[^a-zA-Z]/, ' ')
    word_list = sentence.downcase.split(' ')
    #   TimeLogger("03")
    word_inserts = []
    word_singleton_set = Set.new
    word_list.each do |word|
      word_singleton_set.add(word.downcase)
    end

    #  logger.info "word_set length = #{word_set.length}, word_array = #{word_array}"
    word_singleton_set.each do |word|

      @word_singleton_inserts.push "(#{@word_hash[word]},#{sentence_obj.id}, #{result_page_id}, #{sentence_obj.paragraph_id})"
    end
    #  logger.info "@word_singleton_inserts = #{@word_singleton_inserts}"


    for i in 0..word_list.length-1
      word_1 = @word_prime_hash[word_list[i]]


      if i<word_list.length-1
        for j in (i+1) .. [i+@max_separation, word_list.length-1].min
          word_2 = @word_prime_hash[word_list[j]]
          #    logger.info "word_list[i] = #{word_list[i]}, word_list[j] = #{word_list[j]}, @word_prime_hash = [#{ @word_prime_hash[word_list[i]]},#{ @word_prime_hash[word_list[j]]}]"
          @word_pairs_inserts.push "(#{word_1 * word_2},#{j-i}, #{result_page_id}, #{sentence_obj.id})"
        end
      end
    end

    #   TimeLogger("05")
    #  logger.info "ProcessSentence end"


  end

  def ProcessSentenceOld(sentence, result_page_id, paragraph_id)
    logger.info "ProcessSentence begin"
    #logger.info "original sentence: #{sentence}"

    #TimeLogger("01")

    sentence_object = Sentence.new
    sentence_object.content = sentence
    sentence_object.paragraph_id = paragraph_id
    sentence_object.save
    word_count=1
    word_array = Array.new
    word_set = Set.new
    sentence = sentence.gsub(/[^a-zA-Z]/, ' ')
    # TimeLogger("02")
    #  logger.info "sentence without punctuation: #{sentence}"
    word_list = sentence.split(' ')
    #  logger.info "v1"
    sentence.split(' ').each do |word|
      # logger.info "#{word_count}, Word: #{word}"
      word_count=word_count+1
      #   logger.info "v2"
      if word.length > 1
        #      logger.info "v3"
        word_object = Word.find_by_word_name(word.downcase)
        #     logger.info "v4"
        if word_object == nil
          #      logger.info "v5"
          word_object = Word.new

          word_object.word_name = word.downcase
          if Word.exists?
            #       logger.info "v6"
            #     logger.info "last word is #{Word.last.word_prime}"
            possible_prime = Word.last.word_prime

            #        logger.info "v7 #{possible_prime}"
            possible_prime = possible_prime + 2
            #        logger.info "v7a #{possible_prime}"
            while @@primes.prime?(possible_prime) == false
              possible_prime = possible_prime + 2
              #       logger.info "v8"
            end

          else
            #       logger.info "v9"
            possible_prime = 3

          end
          #    logger.info "v10"
          word_object.word_prime = possible_prime
          word_object.save
        end
        #  logger.info "v11"
        word_array << word_object
        #  logger.info "v12"
        word_set.add(word_object.id)
        #    logger.info "v13"
      end
      #  logger.info "v14"
    end
    #   TimeLogger("03")
    word_inserts = []

    #  logger.info "word_set length = #{word_set.length}, word_array = #{word_array}"
    word_set.each do |word_id|
      word_inserts.push "(#{word_id},#{sentence_object.id}, #{result_page_id})"
      # word_singleton = WordSingleton.new
      #  word_singleton.word_id = word_id
      #  word_singleton.sentence_id = sentence_object.id
      #  word_singleton.result_page_id = result_page_id
      #   word_singleton.save
    end
    if word_inserts.length > 0
      sql = "INSERT INTO word_singletons (word_id, sentence_id, result_page_id) VALUES #{word_inserts.join(', ')}"
      # logger.info "sql = #{sql}"
      sql_save(sql)
    end
    # TimeLogger("04")
    pair_inserts = []

    for i in 0..word_array.length-1
      word_1 = word_array[i]


      if i<word_array.length-1
        for j in (i+1) .. [i+@max_separation, word_array.length-1].min
          word_2 = word_array[j]
          #word_pair = WordPair.new
          # word_pair.word_multiple = word_1.word_prime * word_2.word_prime
          # word_pair.separation = j-i
          # word_pair.result_page_id = result_page_id
          # word_pair.sentence_id = sentence_object.id
          pair_inserts.push "(#{word_1.word_prime * word_2.word_prime},#{j-i}, #{result_page_id}, #{sentence_object.id})"
          # word_pair.save
          #        word_pair.save if not WordPair.exists?(:word_multiple => word_pair.word_multiple, :result_page_id => result_page_id, :sentence_id => sentence_object.id)
        end
      end
    end
    if pair_inserts.length > 0
      sql = "INSERT INTO word_pairs (word_multiple, separation, result_page_id,sentence_id) VALUES #{pair_inserts.join(', ')}"
      # logger.info "sql = #{sql}"
      sql_save(sql)
    end

    #   TimeLogger("05")
    logger.info "ProcessSentence end"
  end

  def ProcessParagraphs(paragraphs, result_page_id)
    logger.info "ProcessParagraphs begin, paragraphs length = #{paragraphs.length}"
    paragraph_count = 0
    @paragraph_inserts =[]
    paragraph_block_num = 100

    for par_count in 0..paragraphs.length-1
      par = paragraphs[par_count]

      if @max_paragraph_number<0 || paragraph_count<@max_paragraph_number
        par_text = par.text

        #the code below is to deal with a bug in reading paragraphs
        if par_count < (paragraphs.length-2)
          par_index = par_text.index(paragraphs[par_count+1].text)
          if par_index != nil and par_text.index(paragraphs[par_count+2].text) !=nil
            par_text = par_text[0..par_index-1]
          end
        end
        @last_paragraph = par_text
        paragraph_count=paragraph_count+1
        #@paragraph_inserts.push "(\"#{par_text.gsub('"', '\"')}\",#{result_page_id})"
        @paragraph_inserts.push "(\'#{par_text.gsub("'","''")}\',#{result_page_id})" # psql

        if @paragraph_inserts.length%paragraph_block_num == 0
          save_paragraphs(result_page_id)

        end
      end

    end
    if @paragraph_inserts.length > 0
      save_paragraphs(result_page_id)


    end
    logger.info "ProcessParagraphs end"

  end

  def save_paragraphs(result_page_id)
  #  logger.info "rwv1001 a"
    if Paragraph.exists?()
  #    logger.info "rwv1001 b"
      max_id = Paragraph.maximum('id')
      logger.debug ""
    else
      max_id = 0;
    end
    logger.debug ""
    sql = %Q"INSERT INTO paragraphs (content, result_page_id) VALUES #{@paragraph_inserts.join(', ')}"
    # logger.info "sql = #{sql}"
    sql_save(sql)
 #   logger.info "rwv1001 c"
    paragraphs = Paragraph.where("id > #{max_id}").order("id asc")
 #   logger.info "rwv1001 d"
    par_sentences = []
    paragraphs.each do |paragraph|
      par_sentence = Hash.new
      par_sentence[:sentences] = paragraph.content.split('.')
      par_sentence[:paragraph_id] = paragraph.id
      par_sentences.push(par_sentence)
    end
#    logger.info "rwv1001 e"
    ProcessSentences(par_sentences, result_page_id)
 #   logger.info "rwv1001 ee"
    @paragraph_inserts =[]


  end

  # @param [String] url
  # @param [String] base_url
  # @param [number] current_level
  # @return [Object]
  def ProcessPage(url, current_level, parent_id)
    logger.info "ProcessPage begin"
    new_crawler_page = 0
    # logger.info "AA parent_id = #{parent_id}, level = #{current_level}"
    if (@current_page_store<@max_page_store or @max_page_store<0)
      new_parent_id = 0
      crawl_number =0
      last_slash = url.rindex("/")
      last_period = url.rindex(".")
      last_hash = url.rindex("#")
      if last_hash != nil
        url = url[0, last_hash]
      end
      if last_period == nil
        logger.info "01c"
        return
      end

      if last_slash < url.length-1
        if last_period > last_slash then
          file_name = url[last_slash+1, url.size]
          base_url = url[0, last_slash+1]
        else
          logger.info "01a"
          return
          file_name = 'index.html'
          base_url = url + '/'
        end
      else
        logger.info "01b"
        return
        file_name = 'index.html'
        base_url = url
      end
      url = base_url + file_name


      logger.info "process_hash url: #{url}, base_url: #{base_url}, file_name: #{file_name}, level: #{current_level}"
      next_level = current_level+1
      new_pages = Set.new

      second_attempt = false

      if CrawlerPage.exists?(URL: url, domain_crawler_id: self.id)
        new_crawler_results = CrawlerPage.where(URL: url, domain_crawler_id: self.id)
        new_crawler_page = new_crawler_results.first
        #        logger.info "ProcessPage 07 new_crawler_results length is #{new_crawler_results.length}"
      else
        new_crawler_page = CrawlerPage.new
        new_crawler_page.URL = url
        new_crawler_page.name = ""
        new_crawler_page.domain_crawler_id = self.id
        #       logger.info "ProcessPage 08"
      end

      begin
        doc = Nokogiri::HTML(open(url))
      rescue Exception => e
        second_attempt = true
        logger.info "Couldn't read \"#{ url }\": #{ e }"
        logger.info "let's sleep for 4ss"
        sleep(4)

      end
      begin
        if second_attempt == true
          logger.info "2nd attempt read"
          doc = Nokogiri::HTML(open(url))

        end
        @page_count = @page_count +1
        logger.info "ProcessPage #{@page_count}"


        logger.info "let's sleep for 5s"
        sleep(5)
        crawler_pagea = CrawlerPage.where(URL: url)
        read_page = true
        if crawler_pagea.length >0
          read_page = false
        end


        # hash_value = Digest::MD5.hexdigest(body)
        #      logger.info "ProcessPage 03"
        @current_page_store = @current_page_store +1
        paragraphs = doc.xpath('//p') + doc.xpath('//td')

        #     logger.info "Number of paragraphs =  #{paragraphs.length}"
        #logger.info "Paragraph 0 is #{paragraphs[0].text}"
        #logger.info "Paragraph 1 is #{paragraphs[1].text}"
        #logger.info "Paragraph 2 is #{paragraphs[2].text}"
        #logger.info "Paragraph 3 is #{paragraphs[3].text}"
        content = ""
        paragraphs.each do |par|
          #logger.info "par content is #{par.text}"
          #content << "<p>" << ActionController::Base.helpers.strip_tags(par.text) << "</p>\n\n"
          #par_text = Nokogiri::HTML(par).xpath('//text()').map(&:text).join(' ')
          #content << "<p>" << par.text.gsub(/<[^>]*>/, " ") << "</p>\n\n"
          content << "<p>" << Digest::MD5.hexdigest(par.xpath('//text()').map(&:text).join(' ')) << "</p>\n\n"
        end
        #     logger.info "ProcessPage 04"
        #logger.info "body content is #{content}"

        hash_value = Digest::MD5.hexdigest(content)
        #   logger.info "hash_value is #{hash_value}"
        result_page = ResultPage.find_by_hash_value(hash_value)

        #     logger.info "ProcessPage 05"
        if (result_page==nil or @always_process) and paragraphs.length > 0
          #     logger.info "ProcessPage 06"
          result_page = ResultPage.new
          # result_page.content = content
          result_page.hash_value = hash_value
          result_page.save

          ProcessParagraphs(paragraphs, result_page.id)
        else

          logger.info "Page already processed or empty: #{url}, paragraphs.length = #{paragraphs.length}"
        end


        #      logger.info "ProcessPage 09"
        logger.info "new_crawler_page: #{new_crawler_page.inspect}"

        new_crawler_page.name = file_name
        new_crawler_page.result_page_id = result_page.id


        if parent_id!=0
          #new_crawler_page.parent_id = parent_id *********************
        end
        #        logger.info "ProcessPage 10"

        new_crawler_page.save
        new_parent_id = new_crawler_page.id


        if @first_page_id == 0
          @first_page_id = new_crawler_page.id
          self.crawler_page_id = @first_page_id
          #      logger.info "Setting first crawler page to #{@first_page_id}"
        else
          logger.info "First crawler page not set, already #{@first_page_id}"
        end
        #       logger.info "ProcessPage 11"

        #    logger.info "ProcessPage 12"


        #      logger.info "Saved url #{url}"


        #       logger.info "ProcessPage 3"
        if new_crawler_page.depth <  @max_level
          links = doc.xpath('//a')
        links.each do |item|

          logger.info "Href1: #{item['href'].inspect}, #{item['href'].class}"

          href_str = item["href"]
          if href_str.nil? or href_str =~ /^javascript/ or href_str =~ /^mailto:/
            logger.info "Nil case: #{href_str}"
            href_str = ""
          end
          if href_str =~/pdf$/ or href_str =~ /wav$/
            href_str = ""
          end
          if href_str =~ /^#{base_url}/
            logger.info "we have a match for #{href_str}"
            href_str.sub! base_url, ''
            logger.info "Updated: #{href_str}"
          end
          last_hash = href_str.rindex("#")
          if last_hash !=nil
            if last_hash >0
              href_str = href_str[0..last_hash-1]
            else
              href_str = ""
            end
          end

          if href_str =~ /^http:/ or href_str =~ /^https:/
            logger.info "wrong domain: #{href_str}"
            href_str = ""
          end
          new_url = (base_url+href_str).gsub(/\/[^\.\/]+\/\.\./, "")
          logger.info "base_url+href_str =  #{base_url+href_str}"

          if href_str.length >0 and crawl_number < @max_crawl_number
         #   match_value = get_match_value(new_url, url)
            if CrawlerPage.exists?(URL: new_url, domain_crawler_id: self.id)== false

              @current_pages[new_url] ||= next_level
              new_pages.add(new_url)
              crawl_number=crawl_number+1
              aref_crawler_page = CrawlerPage.new
              aref_crawler_page.name = ""
              aref_crawler_page.URL = new_url
           #   aref_crawler_page.match_value = match_value
              aref_crawler_page.domain_crawler_id = self.id
              aref_crawler_page.parent_id = new_parent_id
              aref_crawler_page.save
              logger.info "aref_crawler_page: #{aref_crawler_page.inspect}"
            else
              another_crawler_page = CrawlerPage.where(URL: new_url, domain_crawler_id: self.id).first
              another_parent = another_crawler_page.parent
              logger.info "another_crawler_page: #{another_crawler_page.inspect}"
              logger.info "new_crawler_page: #{new_crawler_page.inspect}"
              if another_crawler_page.depth > new_crawler_page.depth+1
                logger.info "updating parent"
                another_crawler_page.parent_id = new_parent_id
                another_crawler_page.save
                if another_crawler_page.result_page_id == nil
                  new_pages.add(new_url)
                end
              end
            #  if another_parent != nil
              #  another_parent_url = another_parent.URL
             #   if get_match_value(new_url, another_parent_url) < match_value
              #    another_crawler_page.parent_id = new_parent_id
               #   another_crawler_page.match_value = match_value
                  #          another_crawler_page.save
               # end
             # end
            end
          end
        end
        end
          #    logger.info "ProcessPage 13"
          #      logger.info "ProcessPage 4"
      rescue Exception => e
        logger.info "2nd attempt - Couldn't read \"#{ url }\": #{ e }"
        if new_crawler_page.result_page_id != nil
          if new_crawler_page.result_page_id< 0
            new_crawler_page.result_page_id = new_crawler_page.result_page_id - 1
          end
        else
          new_crawler_page.result_page_id = -1
        end
        new_crawler_page.save
      end
      old_parent_id = parent_id

      new_process_pages = []


      new_pages.each do |url|


        parent_id = new_parent_id

        ProcessPage(url, next_level, parent_id)

      end if next_level < @max_level
      parent_id = old_parent_id
    end
  end

  def get_match_value(new_url, parent_url)
    new_url_tokens = new_url.split('/')
    parent_url_tokens = parent_url.split('/')
    match_count = 0
    while match_count< new_url_tokens.length and new_url_tokens[match_count] == parent_url_tokens[match_count]
      match_count= match_count+1
    end
    return match_count


  end

  def reorder_pages

  end

  def fix_domain
    initialize_crawl
    bad_pages = CrawlerPage.where(["(result_page_id  <0 or result_page_id is NULL) and domain_crawler_id = ?", self.id]).order("id asc")
    orig_num_of_bad_pages = bad_pages.length
    bad_pages.each do |bad_page|
      logger.info "fixing bad page: #{bad_page}"
    ProcessPage(bad_page.URL, 0, bad_page.parent_id)
    end
    afterwards_bad_pages = CrawlerPage.where(["(result_page_id  <0 or result_page_id is NULL) and domain_crawler_id = ?", self.id]).order("id asc")
    afterwards_num_of_bad_pages = afterwards_bad_pages.length
    result_str = "Number of bad pages before fixing: #{orig_num_of_bad_pages}. Number of bad pages after fixing:#{afterwards_num_of_bad_pages}."
    return result_str
  end

  def initialize_crawl
    @previous_time =0
    @a=0

    @max_page_store = -1
    @max_crawl_number = 10000
    @max_paragraph_number =-1
    @max_separation = 10
    @current_page_store = 0
    @last_paragraph = ""

    @first_page_id = 0
    @max_level = 4
    @always_process = false
    @connection = ActiveRecord::Base.connection
    @page_count = 0
    @current_pages = Hash.new()
    @current_pages[domain_home_page] = 0

  end

  def crawl
    logger.info "start crawl for URL #{@domain_home_page}"


    update_domain = true
    parent_id = 0

    initialize_crawl



    if DomainCrawler.exists?(domain_home_page: @domain_home_page) or DomainCrawler.exists?(domain_home_page: @domain_home_page[0..-2]) or DomainCrawler.exists?(domain_home_page: @domain_home_page+'/')

      current_version = DomainCrawler.where(domain_home_page: domain_home_page).order("version DESC").first +1
    else

      current_version = 1
    end


    #@domain_crawler.user_id = current_user_id
    #@domain_crawler.version = current_version
    #@domain_crawler.domain_name = domain


    current_level = 0



    ProcessPage(domain_home_page, current_level, parent_id)
    #   logger.info "BB parent_id = #{parent_id}, level = #{current_level}"
    count = 1
    @current_pages.each do |page, level|
      #   logger.info "#{count}: Page = #{page}, Level = #{level}"
      count = count+1
    end


    logger.info "end of crawl"
    #return @current_pages
    return @first_page_id


  end
end

