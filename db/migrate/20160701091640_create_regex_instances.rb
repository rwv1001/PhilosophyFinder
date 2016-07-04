class CreateRegexInstances < ActiveRecord::Migration[5.0]
  def change
    create_table :regex_instances do |t|
      t.integer :user_id
      t.integer :regex_templated_id
      t.string :argument

      t.timestamps
    end
  end
end
