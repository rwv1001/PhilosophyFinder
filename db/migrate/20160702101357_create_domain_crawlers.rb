class CreateDomainCrawlers < ActiveRecord::Migration[5.0]
  def change
    create_table :domain_crawlers do |t|
      t.integer :user_id
      t.integer :version
      t.string :domain_name

      t.timestamps
    end
  end
end
