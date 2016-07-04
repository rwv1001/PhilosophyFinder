class CreateSearchQueries < ActiveRecord::Migration[5.0]
  def change
    create_table :search_queries do |t|
      t.integer :user_id
      t.string :domain
      t.integer :regex_id

      t.timestamps
    end
  end
end
