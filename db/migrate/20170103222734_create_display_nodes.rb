class CreateDisplayNodes < ActiveRecord::Migration
  def change
    create_table :display_nodes do |t|
      t.integer :user_id, index: true
      t.integer :crawler_page_id, index: true


    end
  end
end
