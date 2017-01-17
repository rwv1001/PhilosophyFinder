class AddAccentedToSentences < ActiveRecord::Migration
  def change
    add_column :sentences, :deaccented_content, :text, :default => ''
    add_column :sentences, :accented, :boolean, :default => false
  end
end
