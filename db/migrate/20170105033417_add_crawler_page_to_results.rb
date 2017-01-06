class AddCrawlerPageToResults < ActiveRecord::Migration
  def change
    add_column :result_pages, :crawler_page_id, :integer
    add_column :result_pages, :content, :text, :limit => 1073741823
  end
end
