PAGE = { :users => 0, :domain_crawlers => 1, :search_queries =>2  }.freeze
DEFAULT_PAGE = { :domain_crawler => 1, :search_query => 1  }.freeze
CRAWLER = { :directory => 0, :site => 1}.freeze
GROUP_ACTION = {:select_action => "select_action", :new_group => "new_group", :move_group => "move_group", :add_element => "add_element",:remove_element => "remove_element", :rename =>"rename", :remove_group => "remove_group"}.freeze
DOMAIN_ACTION = {:select_action => "select_action", :search_domain => "search_domain", :search_groups => "search_groups", :new_domain => "new_domain", :grab_domain => "grab_domain", :analyse_domain => "analyse_domain", :fix_domain => "fix_domain", :reorder_pages => "reorder_pages", :deaccent_domain => "deaccent_domain", :set_paragraphs => "set_paragraphs" ,:rename => "rename",:move_domain => "move_domain",:remove_domain => "remove_domain"}
MAX_DISPLAY = 50
MAX_RESULTS = 1000
MAX_QUERY_STORE = 10
SENTENCE_SEPARATION = 11
PARAGRAPH_SEPARATION = 12



