class CreateRegexTemplates < ActiveRecord::Migration
  def change
    create_table :regex_templates do |t|
      t.integer :user_id
      t.string :name
      t.string :expression
      t.string :arg_names
      t.text :help
      t.string :join_code

      t.timestamps
    end
  end
end
