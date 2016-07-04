class CreateParagraphs < ActiveRecord::Migration[5.0]
  def change
    create_table :paragraphs do |t|
      t.text :content
      t.integer :result_page_id

    end
    add_index :paragraphs, :result_page_id, :name => 'result_page_id_ix'
  end
end
