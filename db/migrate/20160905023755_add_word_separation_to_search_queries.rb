class AddWordSeparationToSearchQueries < ActiveRecord::Migration
  def change
    add_column :search_queries, :word_separation, :integer
  end
end
