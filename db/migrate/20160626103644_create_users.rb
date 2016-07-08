class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :email
      t.string :first_name
      t.string :second_name
      t.string :password_digest
      t.integer :current_page, :default => PAGE[:users]
      t.integer :current_domain_crawler_id, :default => 1
      t.timestamps
    end
  end
end
