class WordsOnDuplicateIgnore < ActiveRecord::Migration
  def self.up
    execute "CREATE RULE words_on_duplicate_ignore AS ON INSERT TO words
  WHERE EXISTS(SELECT 1 FROM words WHERE (word_name)=(NEW.word_name))
  DO INSTEAD NOTHING;"
  end
  def self.down
    execute "DROP RULE words_on_duplicate_ignore ON words;"
  end
end
