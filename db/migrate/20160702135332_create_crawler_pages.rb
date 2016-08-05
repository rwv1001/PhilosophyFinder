class CreateCrawlerPages < ActiveRecord::Migration
  def change
    create_table :crawler_pages do |t|
      t.integer :result_page_id
      t.string :URL
      t.string :name
      t.string :ancestry

      t.belongs_to :domain_crawler, index: true

    end
    add_index :crawler_pages, :ancestry
  end
end
