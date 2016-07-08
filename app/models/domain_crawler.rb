require 'nokogiri'
require 'open-uri'
require 'digest/md5'


class DomainCrawler < ApplicationRecord
  has_many :crawler_pages
  belongs_to :crawler_page

  def ProcessSentence(sentence, result_page_id, paragraph_id)
    logger.info "ProcessSentence begin"
    #logger.info "original sentence: #{sentence}"

    sentence_object = Sentence.new
    sentence_object.content = sentence
    sentence_object.paragraph_id = paragraph_id
    sentence_object.save
    word_count=1
    word_array = Array.new
    word_set = Set.new
    sentence = sentence.gsub(/[^a-zA-Z]/, ' ')
    logger.info "sentence without punctuation: #{sentence}"
    word_list = sentence.split(' ')
    sentence.split(' ').each do |word|
     # logger.info "#{word_count}, Word: #{word}"
      word_count=word_count+1
      if word.length > 1

        word_object = Word.find_by_word_name(word)

        if word_object == nil

          word_object = Word.new

          word_object.word_name = word

          word_object.save
        end

        word_array << word_object.id

        word_set.add(word_object.id)
      end
    end
    logger.info "word_set length = #{word_set.length}, word_array = #{word_array}"
    word_set.each do |word_id|
      word_singleton = WordSingleton.new
      word_singleton.word_id = word_id
      word_singleton.sentence_id = sentence_object.id
      word_singleton.result_page_id = result_page_id
      word_singleton.save
    end
    for i in 0..word_array.length-1
      word_1 = word_array[i]

=begin
      if i>0
        for j in[0,i-@max_separation].max..(i-1)
          word_2 = word_array[j]
          word_pair = WordPair.new
          word_pair.word_1 = word_1
          word_pair.word_2 = word_2
          word_pair.separation = j-i
          word_pair.result_page_id = result_page_id
          word_pair.sentence_id = sentence_object.id
          word_pair.save

        end
      end
=end

      if i<word_array.length-1
        for j in (i+1) .. [i+@max_separation, word_array.length-1].min
          word_2 = word_array[j]
          word_pair = WordPair.new
          word_pair.word_1 = word_1
          word_pair.word_2 = word_2
          word_pair.separation = j-i
          word_pair.result_page_id = result_page_id
          word_pair.sentence_id = sentence_object.id
          word_pair.save if not WordPair.exists?(:word_1 => word_1, :word_2 => word_2, :result_page_id => result_page_id, :sentence_id => sentence_object.id)
        end
      end
    end
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
    paragraphs.each do |par|

      if @max_paragraph_number<0 || paragraph_count<@max_paragraph_number
        #index_paragraphs
        par_text = par.text
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
            logger.info "#{sentence_count}, Sentence: #{sentence}"
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
    logger.info "AA parent_id = #{parent_id}, level = #{current_level}"
    new_parent_id = 0
    crawl_number =0
    last_slash = url.rindex("/")
    last_period = url.rindex(".")

    if last_slash < url.length-1
      if last_period > last_slash then
        file_name = url[last_slash+1,url.size]
        base_url = url[0,last_slash+1]
      else
        file_name = ''
        base_url = url + '/'
      end
    else
      file_name = ''
      base_url = url
    end



    logger.info "process_hash url: #{url}, base_url: #{base_url}, file_name: #{file_name}, level: #{current_level}"
    next_level = current_level+1
    new_pages = Set.new
    begin
      doc = Nokogiri::HTML(open(url))



      #blogger.info "Body is #{body}"

      # hash_value = Digest::MD5.hexdigest(body)
      if (@current_page_store<@max_page_store or @max_page_store<0)
        @current_page_store = @current_page_store +1
        paragraphs = doc.xpath('//p')
        logger.info "Number of paragraphs =  #{paragraphs.length}"
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
       #logger.info "body content is #{content}"

        hash_value = Digest::MD5.hexdigest(content)
        logger.info "hash_value is #{hash_value}"
        result_page = ResultPage.find_by_hash_value(hash_value)
        if result_page==nil or @always_process
          result_page = ResultPage.new
         # result_page.content = content
          result_page.hash_value = hash_value
          result_page.save

          ProcessParagraphs(paragraphs, result_page.id)

        else

          logger.info "Page already processed #{url}"
        end
        logger.info "ProcessPage 2"
        new_crawler_page = CrawlerPage.new
        logger.info "ProcessPage 2a"
        new_crawler_page.result_page_id = result_page.id
        logger.info "ProcessPage 2b"
        new_crawler_page.URL = url
        logger.info "ProcessPage 2c"
        new_crawler_page.domain_crawler_id = id
        logger.info "ProcessPage 2e"

        logger.info "parent_id = #{parent_id}, level = #{current_level}"
        logger.info "inspect new_crawler_page #{new_crawler_page.inspect}"
        if parent_id!=0
          logger.info "ProcessPage 2f"
          new_crawler_page.parent_id = parent_id

        end
        logger.info "ProcessPage 2g"
        logger.info "inspect new_crawler_page #{new_crawler_page.inspect}"
        logger.info "ProcessPage 2h"
        new_crawler_page.save
        new_parent_id = new_crawler_page.id

        logger.info "@first_page_id = #{@first_page_id}"
        if @first_page_id == 0
          @first_page_id = new_crawler_page.id
          self.crawler_page_id = @first_page_id
          logger.info "Setting first crawler page to #{@first_page_id}"
        else
          logger.info "First crawler page not set, already #{@first_page_id}"
        end

        logger.info "Saved url #{url}"
      end
      logger.info "ProcessPage 3"
      links = doc.xpath('//a')
      links.each do |item|

        #logger.info "Href1: #{item['href'].inspect}, #{item['href'].class}"

        href_str = item["href"]
        if href_str =~ /^#{base_url}/
          # logger.info "we have a match for #{href_str}"
          href_str.sub! base_url, ''
          # logger.info "Updated: #{href_str}"
        elsif href_str.nil? or href_str =~ /\#/ or href_str =~ /^javascript/
         # logger.info "Nil case: #{href_str}"
        elsif href_str !~ /^http:/ and href_str !~ /^https:/ and crawl_number < @max_crawl_number

          @current_pages[base_url+href_str] ||= next_level
          new_pages.add(base_url+href_str)
          crawl_number=crawl_number+1

        end
      end
      logger.info "ProcessPage 4"
    rescue Exception => e
      logger.info "Couldn't read \"#{ url }\": #{ e }"
    end
    old_parent_id = parent_id

    new_pages.each do |url|
      logger.info "let's sleep"
      sleep(10)

      parent_id =  new_parent_id

      ProcessPage(url, next_level, parent_id)

    end if next_level < @max_level
    parent_id = old_parent_id

  end

  def crawl
    logger.debug "start crawl for URL #{@domain_home_page}"

    update_domain = true
    @max_page_store = 20
    @max_crawl_number = 20
    @max_paragraph_number =2
    @max_separation = 3
    @current_page_store = 0
    @last_paragraph = ""
    parent_id = 0
    @first_page_id = 0
    @max_level = 4
    @always_process = true


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
    logger.info "BB parent_id = #{parent_id}, level = #{current_level}"
    count = 1
    @current_pages.each do |page, level|
      logger.info "#{count}: Page = #{page}, Level = #{level}"
      count = count+1
    end



    logger.info "end of crawl"
    #return @current_pages
    return @first_page_id

  end

end

