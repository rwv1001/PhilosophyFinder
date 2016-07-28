class CreateSearchResults < ActiveRecord::Migration
  def change
    create_table :search_results do |t|
      t.integer :user_id
      t.integer :permissions
      t.integer :permissions_group_id
      t.integer :search_query_id
      t.text :highlighted_result
      t.integer :sentence_id
      t.integer :crawler_page_id
      t.boolean :hidden, :default => false
      t.boolean :selected, :default => false
      t.integer :begin_display_paragraph_id
      t.integer :end_display_paragraph_id

      t.timestamps
    end
    add_index :search_results, :search_query_id, :name => 'search_query_id_ix'
  end
end
