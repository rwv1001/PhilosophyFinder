class AddPreviousGroupSearchIdsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :group_id, :integer
    add_column :users, :search_query_id, :integer
  end
end
