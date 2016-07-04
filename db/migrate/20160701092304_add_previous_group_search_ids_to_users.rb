class AddPreviousGroupSearchIdsToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :group_id, :integer
    add_column :users, :search_query_id, :integer
  end
end
