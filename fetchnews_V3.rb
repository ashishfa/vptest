require 'rubygems'
require 'mechanize'
require 'mysql'


#fetches data from google for the given kw of given category and stores it in DB
def fetchdata_google(kw,cat)
	puts "#{Time.new}:fetching from google..."
	res = Hash.new
	qurl = "http://news.google.co.in/news?hl=en&um=1&ie=UTF-8&output=rss&q="
	qurlx = qurl + kw
  	puts qurlx
  	html = fetch_link(qurlx) 	
	doc = Nokogiri::XML(html)
	doc.xpath("//item").each do |it|
#		puts it.to_html
		res["title"] = it.xpath("./title").text
#		puts title
		link = it.xpath("./link").text
		x = link.split("url=")
		res["link"] = x[1]
#		puts link
		date = it.xpath("./pubDate").text
		res["date"] =DateTime.parse(date)
#		puts date
#		res["desc"] = it.xpath("./description").text
#		tt = it.xpath("./description")
		res["desc"] = Nokogiri::HTML(it.xpath("./description").text).text
		res["source"] = "google_news"
		res["cat"] = cat
		res["kw"]	 = kw
#		puts res["desc"]
		puts "saving #{res['title']} ..."
		save_content(res)
	end	
			
end #fetchdata_google


#fetches data from google_blog for the given kw of given category and stores it in DB
def fetchdata_google_blog(kw, cat)
	puts "#{Time.new}:fetching from google_blog..."
	res = Hash.new
	qurl = "https://www.google.com/search?hl=en&tbm=blg&num=20&output=rss&q="
	qurlx = qurl + kw
  	puts qurlx
  	html = fetch_link(qurlx) 	
	doc = Nokogiri::XML(html)
	doc.xpath("//item").each do |it|
#		puts it.to_html
		res["title"] = Nokogiri::HTML(it.xpath("./title").text).text
#		puts title
		link = it.xpath("./link").text
		res["link"] = link
#		puts link
		date = it.xpath("./dc:date").text
		res["date"] =DateTime.parse(date)
#		puts date
#		res["desc"] = it.xpath("./description").text
#		tt = it.xpath("./description")
		res["desc"] = Nokogiri::HTML(it.xpath("./description").text).text
		res["source"] = "google_blog"
		res["cat"] = cat
		res["kw"]	 = kw
#		puts res["desc"]
		puts "saving #{res['title']} ..."
		save_content(res)
	end	
			
end #fetchdata_google_blog



#fetches data from bing for the given kw of given category and stores it in DB
def fetchdata_bing(kw,cat)
	puts "#{Time.new}:fetching from bing..."
	res = Hash.new
	qurl = "http://api.bing.com/rss.aspx?Source=News&Market=en-US&Version=2.0&Query="
	qurlx = qurl + kw
  	puts qurlx
  	html = fetch_link(qurlx) 	
	doc = Nokogiri::XML(html)
	doc.xpath("//item").each do |it|
#		puts it.to_html
		res["title"] = it.xpath("./title").text
#		puts title
		link = it.xpath("./link").text
		res["link"] = link
		#		puts link
		date = it.xpath("./pubDate").text
		res["date"] =DateTime.parse(date)
#		puts date
#		res["desc"] = it.xpath("./description").text
#		tt = it.xpath("./description")
		res["desc"] = Nokogiri::HTML(it.xpath("./description").text).text
		res["source"] = "bing_news"
		res["cat"] = cat
		res["kw"]	 = kw
#		puts res["desc"]
		puts "saving #{res['title']} ..."
		save_content(res)
	end	
			
end #fetchdata_bing



#fetches data from yahoo for the given kw of given category and stores it in DB
def fetchdata_yahoo(kw,cat)
	puts "#{Time.new}:fetching from yahoo..."
	res = Hash.new
	qurl = "http://news.search.yahoo.com/rss?ei=UTF-8&p="
	qurlx = qurl + kw
  	puts qurlx
  	html = fetch_link(qurlx) 	
	doc = Nokogiri::XML(html)
	doc.xpath("//item").each do |it|
#		puts it.to_html
		res["title"] = it.xpath("./title").text
#		puts title
		link = it.xpath("./link").text
		x = link.split("\/\*\*")
		puts link
#		puts " lenth is #{x.length}"
		if x.length ==1
			res["link"] = URI.unescape(link)
		else
			res["link"] = URI.unescape(x[1])
		end

		date = it.xpath("./pubDate").text
		res["date"] =DateTime.parse(date)
#		puts date
#		res["desc"] = it.xpath("./description").text
#		tt = it.xpath("./description")
		res["desc"] = Nokogiri::HTML(it.xpath("./description").text).text
		res["source"] = "yahoo_news"
		res["cat"] = cat
		res["kw"]	 = kw
#		puts res["desc"]
		puts "saving #{res['title']} ..."
		save_content(res)
	end	
			
end #fetchdata_yahoo


#fetch a link and terurn the html 
def fetch_link(uri)
	r = rand(3)
	sleep(1+r)
	a = Mechanize.new {	|agent|
		agent.user_agent_alias = 'Mac Safari'
	}
	page = a.get(uri)
	#	puts page.body
	return page.body
end # fetch link





#saves the content in the data table for each result with its link, title , description, keyword, category, source of the link(google news or  bing etc.) 
def save_content(record)
	
	title = record["title"]
	link = record["link"]
	desc = record["desc"]
	source = record["source"]
	adate = record["date"]
	cat = record["cat"]
	kw = record["kw"]
	
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
		
	     db.query("INSERT INTO data ( `link`,`title`,`date`,`source`,`cat`,`kw`,`desc` ) VALUES ('#{link}','#{db.escape_string(title)}','#{adate}','#{source}','#{cat}','#{kw}','#{db.escape_string(desc)}') ")
		
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end	
end



#fetch keywords based links for a given category. 
def fetch_type(category)
	kwfile = File.dirname(__FILE__)+"/"+ category+".kw"
	puts "#{Time.new}: start #{kwfile} category"	
	counter = 1
	file = File.new(kwfile, "r")
	while (kw = file.gets)
		kw = kw.chomp
		puts "#{counter}: processing  #{kw} ..."
		fetchdata_google_blog(kw,category)
		fetchdata_yahoo(kw,category)
		fetchdata_bing(kw,category)
		fetchdata_google(kw,category)
		
		puts
		counter = counter + 1
	end
	puts "total #{counter-1} keywords processed for #{kwfile} category"
	puts "#{Time.new}: end #{kwfile} category"	
	puts
	file.close		
end

#fetchdata_google_blog("ice cream","catx")
#save_content(0)
#fetch_type("xyz")



#fetch data for following categories...

fetch_type("restaurant")
fetch_type("real_estate")



#puts "#{Time.new}: end for resturant"
#puts "http%3a//lifewise.canoe.ca/FoodDrink/2012/06/27/19925331.html%3f"
#puts URI.unescape("http%3a//lifewise.canoe.ca/FoodDrink/2012/06/27/19925331.html%3f")
#puts File.dirname(__FILE__)+"/"





