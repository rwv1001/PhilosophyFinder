class CreateGroupNames < ActiveRecord::Migration[5.0]
  def change
    create_table :group_names do |t|
      t.integer :user_id
      t.string :name
      t.string :ancestry

      t.timestamps
    end
  end
end
