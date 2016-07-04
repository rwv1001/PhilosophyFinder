class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :email
      t.string :first_name
      t.string :second_name
      t.string :password_digest

      t.timestamps
    end
  end
end
