TOKENS = ["<span class=\"highlight-sentence\">","<span class=\"highlight\">","</span>"]

class GroupName < ApplicationRecord
  has_ancestry
  has_many :group_elements,  :dependent => :destroy
  def AddResults(result_ids, current_user_id)
    logger.info "AddResult ids: #{result_ids}"
    add_count = 0;
    present_count = 0;
    result_ids.each do |result_id|
      search_result = SearchResult.find_by_id(result_id)
      paragraph_id = search_result.begin_display_paragraph_id
      group_elements = GroupElement.where(paragraph_id: paragraph_id, group_name_id: self.id)

      if group_elements.length == 0
        logger.info "AddResult id: #{result_id}"
        add_count = add_count+1
        group_element = GroupElement.new
        group_element.group_name_id = self.id;
        group_element.paragraph_id = paragraph_id
        group_element.search_result_id = result_id;
        group_element.user_id =current_user_id
        group_element.save;
      else
        group_element = group_elements.first
        present_result_id = group_element.search_result_id
        if present_result_id != result_id
          present_result = SearchResult.find_by_id(present_result_id).highlighted_result
          search_result.highlighted_result = MergeResuls(present_result, search_result.highlighted_result)
          group_element.search_result_id = search_result.id
          group_element.save;
          search_result.save;


        end
        logger.info "AddResult id present: #{result_id}"
        present_count = present_count+1;
      end
      paragraph_id = search_result.begin_display_paragraph_id
      if UserParagraph.exists?(user_id: current_user_id, paragraph_id: paragraph_id) == false
        logger.info "Add UserParagraph paragraph_id: #{paragraph_id}"
        user_paragraph = UserParagraph.new
        user_paragraph.user_id = current_user_id
        user_paragraph.paragraph_id = paragraph_id
        user_paragraph.save
      end
    end
    ret_val = {:add_count => add_count, :present_count => present_count}
    return ret_val
  end


  def get_span_tokens(str)
    word_span_matches = str.to_enum(:scan, TOKENS[1]).map{Regexp.last_match}
    end_span_matches = str.to_enum(:scan, TOKENS[2]).map{Regexp.last_match}
    token_pairs0 = word_span_matches.map{|match| match.offset(0)[1]}
    token_pairs1 = []
    word_span_matches.each_with_index{|match,ind| j = ind; while j<end_span_matches.length-1 and end_span_matches[j].offset(0)[0]<token_pairs0[ind] do j = j+1 end; token_pairs1 << end_span_matches[j].offset(0)[0]}
    ret_value = []
    ret_value = token_pairs0.size.times.map{|ii| str[token_pairs0[ii], token_pairs1[ii]-token_pairs0[ii]]}
  end

  def MergeResuls(group_highlight_result, to_merge_result)
    match_list = []
    TOKENS.each_with_index{|token,ind| match_list.concat group_highlight_result.to_enum(:scan, token).map{Regexp.last_match}.map{|match| TokenMatch.new(match.offset(0)[0],ind,token.length)}}
    sorted_list = match_list.sort
    offsets = [0]
    offsets.concat (sorted_list.size-1).times.map{|ii| (ii+1).times.map{|jj| sorted_list[jj].length}.inject(:+)}
    offsets.each_with_index{|offset, ind| sorted_list[ind].pos = sorted_list[ind].pos - offset }
    strip_highlights = group_highlight_result.gsub(/#{TOKENS.join('|')}/,"")
    new_tokens = get_span_tokens(to_merge_result)
    spaced_new_tokens=new_tokens.map{|new_token| new_token.split(' ').join('\s*')}

    matches = strip_highlights.to_enum(:scan, /#{spaced_new_tokens.join('|')}/im).map { Regexp.last_match }
    matches.each do |match|  sorted_list << TokenMatch.new(match.offset(0)[0],1,TOKENS[1].length) << TokenMatch.new(match.offset(0)[1],2,TOKENS[2].length) end
    updated_list = sorted_list.sort

    updated_list.reverse_each do |update| strip_highlights.insert(update.pos,TOKENS[update.type]) end

    return strip_highlights




  end


end

class TokenMatch
  include Comparable
  attr_accessor :pos
  attr :type
  attr :length

  def <=>(anOther)
    pos <=> anOther.pos
  end

  def initialize(pos, type, length)
    @pos = pos
    @type = type
    @length = length
  end

  def inspect
    "<TokenMatch :pos=>#{@pos}, :type=>#{@type}, :length=>#{@length}>"
  end
end
