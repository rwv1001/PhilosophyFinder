class CreateDomainCrawlers < ActiveRecord::Migration
  def change
    create_table :domain_crawlers do |t|
      t.integer :user_id
      t.integer :permissions
      t.integer :permissions_group_id
      t.integer :version, :default => 1
      t.string :domain_home_page
      t.string :short_name
      t.belongs_to :crawler_page, index: true #first_page
      t.text :description

      t.timestamps
    end
  end
end
