class CreateSearchQueries < ActiveRecord::Migration
  def change
    create_table :search_queries do |t|
      t.integer :user_id
      t.integer :domain_list_id
      t.integer :page_list_id
      t.string :first_search_term
      t.string :second_search_term
      t.boolean :order_sensitive

      t.timestamps
    end
  end
end
