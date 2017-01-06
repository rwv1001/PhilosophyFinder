class CreateCrawlerRanges < ActiveRecord::Migration
  def change
    create_table :crawler_ranges do |t|
      t.integer :user_id, index: true
      t.integer :begin_id
      t.integer :end_id
    end
  end
end
