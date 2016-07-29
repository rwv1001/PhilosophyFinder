class GroupName < ApplicationRecord
  has_ancestry
  has_many :group_elements
  def AddResults(result_ids, current_user_id)
    logger.info "AddResult ids: #{result_ids}"
    add_count = 0;
    present_count = 0;
    result_ids.each do |result_id|
      hash_value = SearchResult.find_by_id(result_id).hash_value

      if GroupElement.exists?(hash_value: hash_value, group_name_id: self.id) == false
        logger.info "AddResult id: #{result_id}"
        add_count = add_count+1
        group_element = GroupElement.new
        group_element.group_name_id = self.id;
        group_element.search_result_id = result_id;
        group_element.hash_value = hash_value;
        group_element.user_id =current_user_id
        group_element.save;
      else
        logger.info "AddResult id present: #{result_id}"
        present_count = present_count+1;
      end
    end
    ret_val = {:add_count => add_count, :present_count => present_count}
    return ret_val
  end
end
