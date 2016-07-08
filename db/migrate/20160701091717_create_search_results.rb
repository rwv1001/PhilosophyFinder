class CreateSearchResults < ActiveRecord::Migration
  def change
    create_table :search_results do |t|
      t.integer :user_id
      t.integer :permissions
      t.integer :permissions_group_id
      t.integer :search_query_id
      t.integer :marker_begin
      t.integer :marker_end
      t.integer :page_id
      t.integer :sentence_id
      t.integer :begin_display_paragraph_id
      t.integer :end_display_paragraph_id

      t.timestamps
    end
    add_index :search_results, :search_query_id, :name => 'search_query_id_ix'
    add_index :search_results, :page_id, :name => 'page_id_ix'
  end
end
