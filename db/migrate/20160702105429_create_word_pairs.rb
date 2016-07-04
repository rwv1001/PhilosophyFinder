class CreateWordPairs < ActiveRecord::Migration[5.0]
  def change
    create_table :word_pairs do |t|
      t.integer :word_1
      t.integer :word_2
      t.integer :separation
      t.integer :result_page_id
      t.integer :sentence_id



    end
    add_index :word_pairs, [:word_1, :word_2, :result_page_id]
  end
end
