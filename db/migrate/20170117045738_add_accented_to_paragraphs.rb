class AddAccentedToParagraphs < ActiveRecord::Migration
  def change
    add_column :paragraphs, :deaccented_content, :text, :default => ''
    add_column :paragraphs, :accented, :boolean, :default => false
  end
end
