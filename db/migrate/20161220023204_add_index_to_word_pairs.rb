class AddIndexToWordPairs < ActiveRecord::Migration
  def change
    add_index :word_pairs, :sentence_id, :name => 'sentence_id_ix'

  end
end
