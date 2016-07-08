class CreateResultPages < ActiveRecord::Migration
  def change
    create_table :result_pages do |t|
      t.integer :user_id
      t.string :hash_value

      t.timestamps
    end
    add_index :result_pages, :hash_value, :name => 'hash_value_ix'
  end
end
