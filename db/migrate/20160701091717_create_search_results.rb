class CreateSearchResults < ActiveRecord::Migration[5.0]
  def change
    create_table :search_results do |t|
      t.integer :user_id
      t.integer :search_query_id
      t.integer :page_id
      t.integer :marker_begin
      t.integer :marker_end
      t.integer :display_begin
      t.integer :display_end

      t.timestamps
    end
  end
end
