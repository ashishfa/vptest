require 'rubygems'
require 'mechanize'
require 'mysql'


# this code is a module to get the info about a link - fetch it and then extract relevant tags 

#fetch a link and terurn the html 
def fetch_link(uri)
	r = rand(3)
	sleep(0.5)
	a = Mechanize.new {	|agent|
		agent.user_agent_alias = 'Mac Safari'
	}
	page = a.get(uri)
	#	puts page.body
	return page.body
end # fetch link



def fetch_info(url)
	puts "fetching..."
	h = Hash.new
	html = fetch_link(url)
	puts "getting data..."
	doc = Nokogiri::HTML(html)
	doc.xpath('//meta[@property = "og:title"]').each do |node|
		h["title"] = node["content"]
		puts h["title"] 
	end
	doc.xpath('//meta[@property = "og:description"]').each do |node|
		h["desc"] = node["content"]
		puts h["desc"]
	end
	doc.xpath('//meta[@property = "og:image"]').each do |node|
		h["image"] = node["content"]
		puts h["image"]
	end
	return h
end



puts fetch_info("http://www.washingtonpost.com/world/middle_east/saudi-warns-non-muslims-not-to-eat-drink-smoke-in-public-on-ramadan-or-face-expulsion/2012/07/20/gJQA5wdkxW_story.html")

#fetch_info("http://www.washingtonpost.com/world/middle_east/saudi-warns-non-muslims-not-to-eat-drink-smoke-in-public-on-ramadan-or-face-expulsion/2012/07/20/gJQA5wdkxW_story.html")
	
#fetch_info("http://blogs.wsj.com/speakeasy/2012/07/02/in-defense-of-the-75-appetizer/")
