class CreateSaveMySqls < ActiveRecord::Migration
  def change
    create_table :save_my_sqls do |t|
      t.text :save_str


    end
  end
end
