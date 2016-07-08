class CreateGroupNames < ActiveRecord::Migration
  def change
    create_table :group_names do |t|
      t.integer :user_id
      t.string :name
      t.string :ancestry

      t.timestamps
    end
  end
end
