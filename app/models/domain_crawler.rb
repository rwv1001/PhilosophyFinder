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

  def ProcessSentence(sentence, result_page_id, paragraph_id)
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
    logger.info "sentence without punctuation: #{sentence}"
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
    @connection.execute(sql)
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
      @connection.execute(sql)
    end

 #   TimeLogger("05")
    logger.info "ProcessSentence end"
  end

  def ProcessParagraphs(paragraphs, result_page_id)
    logger.info "ProcessParagraphs begin, paragraphs length = #{paragraphs.length}"
    paragraph_count = 0
=begin
    logger.info "AANumber of paragraphs =  #{paragraphs.length}"
    logger.info "AAParagraph 0 is #{paragraphs[0].text}"
    logger.info "AAParagraph 1 is #{paragraphs[1].text}"
    logger.info "AAParagraph 2 is #{paragraphs[2].text}"
    logger.info "AAParagraph 3 is #{paragraphs[3].text}"
=end
    for par_count in 0..paragraphs.length-1
      par = paragraphs[par_count]
#      logger.info "01"

      if @max_paragraph_number<0 || paragraph_count<@max_paragraph_number
        #index_paragraphs
#        logger.info "02"
        par_text = par.text
 #       logger.info "03"
        if par_count < (paragraphs.length-2)
  #        logger.info "04"
          par_index = par_text.index(paragraphs[par_count+1].text)
   #       logger.info "05"
          logger.info "par_index = #{par_index}"

          if par_index != nil and par_text.index(paragraphs[par_count+2].text) !=nil
    #        logger.info "06"
            par_text = par_text[0..par_index-1]
     #       logger.info "07"
          end
      #    logger.info "07a"
        end
    #    logger.info "08"
        @last_paragraph = par_text
        logger.info "#{paragraph_count}, Paragraph: #{par_text}"
        paragraph_count=paragraph_count+1
        new_paragraph = Paragraph.new
        new_paragraph.content = par_text
        new_paragraph.result_page_id = result_page_id
        new_paragraph.save
        sentence_count =1
        sentences = par_text.split('.')
        logger.info "There are #{sentences.length} sentences to process"
        par_text.split('.').each do |sentence|
          if sentence.length>0
    #        logger.info "#{sentence_count}, Sentence: #{sentence}"
            ProcessSentence(sentence, result_page_id, new_paragraph.id)
            sentence_count=sentence_count+1
          end
        end
      end
    end

    logger.info "ProcessParagraphs end"

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
        url = url[0,last_hash]
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
      logger.info "ProcessPage 01"
      begin
        doc = Nokogiri::HTML(open(url))
        logger.info "let's sleep"
        sleep(10)
        logger.info "ProcessPage 02"

        #blogger.info "Body is #{body}"

        # hash_value = Digest::MD5.hexdigest(body)
        logger.info "ProcessPage 03"
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
        logger.info "ProcessPage 04"
          #logger.info "body content is #{content}"

          hash_value = Digest::MD5.hexdigest(content)
       #   logger.info "hash_value is #{hash_value}"
          result_page = ResultPage.find_by_hash_value(hash_value)
        logger.info "ProcessPage 05"
          if (result_page==nil or @always_process) and paragraphs.length > 0
            logger.info "ProcessPage 06"
            result_page = ResultPage.new
            # result_page.content = content
            result_page.hash_value = hash_value
            result_page.save

            ProcessParagraphs(paragraphs, result_page.id)
            if CrawlerPage.exists?(URL: url, domain_crawler_id: self.id)
              new_crawler_results = CrawlerPage.where(URL: url, domain_crawler_id: self.id)
              new_crawler_page = new_crawler_results.first
              logger.info "ProcessPage 07 new_crawler_results length is #{new_crawler_results.length}"
            else
              new_crawler_page = CrawlerPage.new
              new_crawler_page.URL = url
              new_crawler_page.domain_crawler_id =  self.id
              logger.info "ProcessPage 08"
            end
            logger.info "ProcessPage 09"
            logger.info "new_crawler_page: #{new_crawler_page.inspect}"

            new_crawler_page.name = file_name
            new_crawler_page.result_page_id = result_page.id




            if parent_id!=0
              new_crawler_page.parent_id = parent_id
            end
            logger.info "ProcessPage 10"

            new_crawler_page.save
            new_parent_id = new_crawler_page.id


            if @first_page_id == 0
              @first_page_id = new_crawler_page.id
              self.crawler_page_id = @first_page_id
              #      logger.info "Setting first crawler page to #{@first_page_id}"
            else
              logger.info "First crawler page not set, already #{@first_page_id}"
            end
            logger.info "ProcessPage 11"
          else

            logger.info "Page already processed or empty: #{url}"
          end
        logger.info "ProcessPage 12"


    #      logger.info "Saved url #{url}"


 #       logger.info "ProcessPage 3"
        links = doc.xpath('//a')
        links.each do |item|

          logger.info "Href1: #{item['href'].inspect}, #{item['href'].class}"

          href_str = item["href"]
          if href_str.nil?  or href_str =~ /^javascript/ or href_str =~ /^mailto:/
            logger.info "Nil case: #{href_str}"
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
          logger.info "base_url+href_str =  #{base_url+href_str}"

          if href_str.length >0 and crawl_number < @max_crawl_number and CrawlerPage.exists?(URL: base_url+href_str, domain_crawler_id: self.id)== false

            @current_pages[base_url+href_str] ||= next_level
            new_pages.add(base_url+href_str)
            crawl_number=crawl_number+1
            new_crawler_page = CrawlerPage.new
            new_crawler_page.URL = base_url+href_str
            new_crawler_page.domain_crawler_id = self.id
            new_crawler_page.save
            logger.info "new_crawler_page: #{new_crawler_page.inspect}"

          end
        end
        logger.info "ProcessPage 13"
  #      logger.info "ProcessPage 4"
      rescue Exception => e
        logger.info "Couldn't read \"#{ url }\": #{ e }"

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

  def crawl
    logger.info "start crawl for URL #{@domain_home_page}"
    @previous_time =0
    @a=0

    update_domain = true
    @max_page_store = -1
    @max_crawl_number = 10000
    @max_paragraph_number =-1
    @max_separation = 10
    @current_page_store = 0
    @last_paragraph = ""
    parent_id = 0
    @first_page_id = 0
    @max_level = 5
    @always_process = true
    @connection = ActiveRecord::Base.connection


    if DomainCrawler.exists?(domain_home_page: @domain_home_page) or DomainCrawler.exists?(domain_home_page: @domain_home_page[0..-2]) or DomainCrawler.exists?(domain_home_page: @domain_home_page+'/')

      current_version = DomainCrawler.where(domain_home_page: domain_home_page).order("version DESC").first +1
    else

      current_version = 1
    end


    #@domain_crawler.user_id = current_user_id
    #@domain_crawler.version = current_version
    #@domain_crawler.domain_name = domain


    current_level = 0
    @current_pages = Hash.new()
    @current_pages[domain_home_page] = current_level


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

