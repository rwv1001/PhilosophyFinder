desc "Fix Domain"
task :fix_domain => :environment do
  domain_crawler = DomainCrawler.find_by_id(ENV["DOMAIN_CRAWLER_ID"]);
  result_str = domain_crawler.fix_domain()
end