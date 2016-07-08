class CreateWords < ActiveRecord::Migration
  def change
    create_table :words do |t|
      t.string :word_name
    end
    add_index :words, :word_name, :name => 'word_name_ix'
  end
end
