class CreateWordPairs < ActiveRecord::Migration
  def change
    create_table :word_pairs do |t|
      t.integer :word_multiple, :limit => 8
      t.integer :separation
      t.integer :result_page_id, index: true
      t.integer :sentence_id



    end
    add_index :word_pairs, :word_multiple, :name => 'word_multiple_id_ix'
  end

end
