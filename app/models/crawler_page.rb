class CrawlerPage < ApplicationRecord
  belongs_to :domain_crawler
  belongs_to :result_page
  has_ancestry
end
