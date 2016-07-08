# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
SearchQuery.create([{first_search_term: '', second_search_term: ''}])
pages = CrawlerPage.create([{URL: 'Not Set'}])
domain_crawler = DomainCrawler.create([{short_name: 'Not Set', crawler_page: pages.first}])
