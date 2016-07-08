class CreateGroupElements < ActiveRecord::Migration
  def change
    create_table :group_elements do |t|
      t.integer :user_id
      t.integer :group_id
      t.integer :search_result_id

      t.timestamps
    end
  end
end
