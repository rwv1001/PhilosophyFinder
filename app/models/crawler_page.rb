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
    logger.info "*** page_id = #{self.id} in_range? = #{ret_value}, ranges = #{crawler_ranges}"

    return ret_value
  end
end
