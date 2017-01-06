class AddParagraphIdToGroupElements < ActiveRecord::Migration
  def change
    add_column :group_elements, :paragraph_id, :integer
    add_index :group_elements, :paragraph_id, :name => 'group_elements_paragraph_id_ix'
    remove_column :group_elements, :hash_value
  end
end
