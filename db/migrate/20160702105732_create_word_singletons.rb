class CreateWordSingletons < ActiveRecord::Migration
  def change
    create_table :word_singletons do |t|
      t.integer :word_id
      t.integer :result_page_id
      t.integer :sentence_id
    end
    add_index :word_singletons, :word_id, :name => 'word_id_ix'
  end
end
