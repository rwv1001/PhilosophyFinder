class AddDateToCrawlerPages < ActiveRecord::Migration
  def change
    add_column :crawler_pages, :download_date, :date
  end
end
