class CreateWords < ActiveRecord::Migration
  def change
    create_table :words, :primary_key => :word_name  do |t|
      t.integer :id_value, index: true
      t.integer :word_prime, index: true
    end
    change_column :words, :word_name, :string

  end
end
