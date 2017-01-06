class CreateUserParagraphs < ActiveRecord::Migration
  def change
    create_table :user_paragraphs do |t|
      t.integer :user_id, index: true
      t.integer :paragraph_id, index: true
    end
  end
end
