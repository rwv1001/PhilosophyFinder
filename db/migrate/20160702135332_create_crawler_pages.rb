class CreateCrawlerPages < ActiveRecord::Migration[5.0]
  def change
    create_table :crawler_pages do |t|
      t.integer :result_page_id
      t.string :URL
      t.integer :domain_crawler_id

    end
  end
end
