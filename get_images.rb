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
#	puts "fetching..."
	h = Hash.new
	html = fetch_link(url)
#	puts "getting data..."
	doc = Nokogiri::HTML(html)
	doc.xpath('//meta[@property = "og:title"]').each do |node|
		h["title"] = node["content"]
#		puts h["title"] 
	end
	doc.xpath('//meta[@property = "og:description"]').each do |node|
		h["desc"] = node["content"]
#		puts h["desc"]
	end
	doc.xpath('//meta[@property = "og:image"]').each do |node|
		h["url"] = node["content"]
#		puts h["url"]
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
	     db.query("INSERT INTO data_image ( `id`, `title`,`url`,`path`,`desc` ) VALUES (#{id},'#{db.escape_string(title)}','#{db.escape_string(url)}','#{db.escape_string(path)}','#{db.escape_string(desc)}') ")
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end	
end



#update that the image flag = 1 in data table  
def update_data(id)
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
	     db.query("update data set  `image`= 1  where  `id`=#{id}")
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end	
end


# fetch the link from data table and save image details in data_image table 
def fetch_n_update_image(id)
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
     	res1 = db.query("select * from data where id = #{id}")
		while rowx = res1.fetch_hash do
			id=rowx["id"]
			link = rowx["link"]	
			h = fetch_info(link)
			h["id"] = id
			save_content(h)
			update_data(id)
		end
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end
end#


# select data from data table based on date range and if it has images process it 
def select_data(date1, date2)
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
     	res1 = db.query("select * from data where date >= day(#{date1})" )
		while rowx = res1.fetch_hash do
			id=rowx["id"]
			link = rowx["link"]	
			if (is_photo_link(link))
				puts "id #{id} and #{link} is selected for processing... "
#				fetch_n_update_image(id)
			end
		
		end
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end	
end#



# true if the given link is one of the image hosting site.
def is_photo_link(link)
	
	if 	(link.include?("pinterest.com") )  
		return true;
	end
	if	(link.include?("flickr.com") ) 
		return true;
	end
	if	(link.include?("deviantart.com") ) 
		return true;
	end
	if	(link.include?("fotolog.com") ) 
		return true;
	end
	if	(link.include?("shutterfly.com") ) 
		return true;
	end
	if	(link.include?("panoramio.com") ) 
		return true;
	end
	if	(link.include?("photobucket.com") ) 
		return true;
	end

	return false;	

end#


#puts is_photo_link("http://www.photobucket.com/photos/mbb/7634020370/")
#puts fetch_info("http://www.flickr.com/photos/mbb/7634020370/")
#x = 15864
#fetch_n_update_image(x)



