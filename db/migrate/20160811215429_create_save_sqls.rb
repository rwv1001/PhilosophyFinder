class CreateSaveSqls < ActiveRecord::Migration
  def change
    create_table :save_sqls do |t|
      t.text :sql_str,  :limit => 4
    end
  end
end
