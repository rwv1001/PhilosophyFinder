class AddParagraphIdToWordSingletons < ActiveRecord::Migration
  def change
    add_column :word_singletons, :paragraph_id, :integer
    add_index :word_singletons, :paragraph_id, :name => 'word_singletons_paragraph_id_ix'
  end
end
