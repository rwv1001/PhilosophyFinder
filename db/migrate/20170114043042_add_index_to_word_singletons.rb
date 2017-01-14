class AddIndexToWordSingletons < ActiveRecord::Migration
  def change
    add_index :word_singletons, :sentence_id, :name => 'ws_sentence_id_ix'
  end
end
