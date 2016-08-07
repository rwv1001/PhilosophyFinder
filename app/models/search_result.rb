require 'nokogiri'
require 'open-uri'
require 'digest/md5'

class SearchResult < ApplicationRecord
  # @param [String] url
  # @param [String] base_url
  # @param [number] current_level
    # @return [Object]
  has_many :group_elements, :dependent => :destroy

  def self.ProcessHash(url, current_level)

      max_crawl_number = 5
      crawl_number =0
      last_slash = url.rindex("/")
      base_url = url[0,last_slash+1]
      if last_slash < url.length-1
        file_name = url[last_slash+1,url.size]
      else
        file_name = ''
      end



      logger.debug "process_hash url: #{url}, base_url: #{base_url}, file_name: #{file_name}, level: #{current_level}"
      next_level = current_level+1
      new_pages = Set.new
      begin
        doc = Nokogiri::HTML(open(url))
        body = doc.css("body")
        #blogger.debug "Body is #{body}"

        hash_value = Digest::MD5.hexdigest(body)
        if(ResultPage.find_by_URL(url)!=nil)
          result_page = ResultPage.new
          result_page.user_id = current_user
          result_page.URL = url
          result_page.content = body
          result_page.hash_value = hash_value
          result_page.save
          logger.debug "Saved url #{url}"
        end
        links = doc.css("a")
        links.each do |item|

          logger.debug "Href1: #{item['href'].inspect}, #{item['href'].class}"

          href_str = item["href"]
          if href_str =~ /^#{base_url}/
            logger.debug "we have a match for #{href_str}"
            href_str.sub! base_url, ''
            logger.debug "Updated: #{href_str}"
          elsif href_str.nil? or href_str =~ /\#/ or href_str =~ /^javascript/
            logger.debug "Nil case: #{href_str}"
          elsif href_str !~ /^http:/ and href_str !~ /^https:/ and crawl_number < max_crawl_number

            @@current_pages[base_url+href_str] ||= next_level
            new_pages.add(base_url+href_str)
            crawl_number=crawl_number+1

          end
        end
      rescue Exception => e
          logger.debug "Couldn't read \"#{ url }\": #{ e }"
      end

      new_pages.each do |url|
        logger.debug "let's sleep"
        sleep(10)
        self.ProcessHash(url, next_level)
      end if next_level < @@max_level

    end

  def self.search(search)
    url = "http://www.dhspriory.org/thomas/english/ContraGentiles.htm"

    @@max_level = 2
    current_level = 0
    @@current_pages = Hash.new()
    @@current_pages[url] = current_level
    self.ProcessHash(url, current_level)
    count = 1
    @@current_pages.each do |page, level|
      logger.debug "#{count}: Page = #{page}, Level = #{level}"
      count = count+1
    end





    logger.debug "New article: lalalalallalalallalallalallalallalallal"
    if search
      wildcard_search = "%#{search}%"
      all

    else
      all
    end

  end
end
