class CreateGroupElements < ActiveRecord::Migration
  def change
    create_table :group_elements do |t|
      t.integer :user_id
      t.text :note
      t.integer :group_name_id, index: true
      t.integer :search_result_id, index: true
      t.string :hash_value, index: true
      t.timestamps
    end
  end
end
