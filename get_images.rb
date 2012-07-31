require 'rubygems'
require 'mechanize'
require 'mysql'


# this code is fetches a link of image host and extracts the image url and saves to a DB 

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



#saves the content in the data_image table  
def save_content(record)

	id = record["id"]
	title = record["title"]
	desc = record["desc"]
	url = record["url"]
	path  = ""
	
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
	     db.query("INSERT INTO data_image ( `id`, `title`,`url`,`path`,`desc` ) VALUES (id,'#{db.escape_string(title)}','#{db.escape_string(url)}','#{db.escape_string(path)}','#{db.escape_string(desc)}') ")
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end	
end



puts fetch_info("http://www.flickr.com/photos/mbb/7634020370/")

