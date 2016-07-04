class CreateSentences < ActiveRecord::Migration[5.0]
  def change
    create_table :sentences do |t|
      t.text :content
      t.integer :paragraph_id

    end
    add_index :sentences, :paragraph_id, :name => 'paragraph_id_ix'
  end
end
