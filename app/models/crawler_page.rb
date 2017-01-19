class CrawlerPage < ApplicationRecord
  belongs_to :domain_crawler
  belongs_to :result_page
  has_ancestry

  def in_range?(crawler_ranges)
    if crawler_ranges.length == 0
      ret_value = true
    else
      ret_value = false
      ii = 0

      while ii<crawler_ranges.length and ret_value == false and crawler_ranges[ii][0]<=self.id
        if crawler_ranges[ii][1]>= self.id
          ret_value = true
        end
        ii = ii + 1
      end
    end
  #  logger.info "*** page_id = #{self.id} in_range? = #{ret_value}, ranges = #{crawler_ranges}"

    return ret_value
  end

  def self.get_pages_in_range(user_id)
    ranges = CrawlerRange.where(user_id: user_id).order('begin_id asc')
    sql_str = "SELECT * FROM crawler_pages cp WHERE" + ranges.map{|rr| "(cp.id >= #{rr.begin_id} AND cp.id <= #{rr.end_id})" }.join(' OR ')
    logger.info "get_pages in range sql_str = #{sql_str}"
    pages = CrawlerPage.find_by_sql(sql_str)
    return pages


  end

  def has_good_children?
    ids = self.child_ids
    if ids.length == 0
      return false
    end
    sql_str = "SELECT 1 FROM crawler_pages WHERE id IN (#{ids.join(' ,')}) AND result_page_id > 0 LIMIT 1"
 #   logger.info "has_good_children? sql str = #{sql_str}"
    if CrawlerPage.find_by_sql(sql_str).length > 0
      return true;
    else
      return false;
    end


  end
end
