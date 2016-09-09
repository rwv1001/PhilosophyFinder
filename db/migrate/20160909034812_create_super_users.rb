class CreateSuperUsers < ActiveRecord::Migration
  def change
    create_table :super_users do |t|
      t.integer :user_id, index: true
    end
  end
end
