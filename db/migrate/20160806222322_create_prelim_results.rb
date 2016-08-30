class CreatePrelimResults < ActiveRecord::Migration
  def change
    create_table :prelim_results do |t|
      t.integer :search_query_id,  index: true
      t.integer :sentence_id

    end
  end
end
