require 'rubygems'
require 'mechanize'
require 'mysql'
require 'json'

# the scripts searches and  saves twits in the twits table along with other details 
# V2 fetching data from twiter where type is mixed - i.e. recent + popular ...

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





def save_content(record)
	
	from_user_id = record["from_user_id"]
	from_user = record["from_user"]
	link = ""
	twit = record["twit"]
	twit_id = record["twit_id"]
	adate = record["date"]
	retwit_count = record["retwit_count"]
	cat = record["cat"]
	kw = record["kw"]
	
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
		
	     db.query("INSERT INTO twits ( `link`,`twit_id`,`twit`,`date`,`from_user`,`from_user_id`,`retwit_count`,`cat`,`kw` ) VALUES ('#{link}','#{twit_id}','#{db.escape_string(twit)}','#{adate}','#{from_user}','#{from_user_id}','#{retwit_count}','#{cat}','#{kw}') ")
		
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
		search_twits(kw,category)
		puts
		counter = counter + 1
	end
	puts "total #{counter-1} keywords processed for #{kwfile} category"
	puts "#{Time.new}: end #{kwfile} category"	
	puts
	file.close		
end



def search_twits(kw,cat)
	puts "#{Time.new}:fetching from twitter..."
	res = Hash.new
	qurl = "http://search.twitter.com/search.json?rpp=100&result_type=mixed&lang=en&include_entities=true&q="
	qurlx = qurl + kw
  	puts qurlx
  	text = fetch_link(qurlx)
  	hh = Hash.new 	
#	puts text
	h = JSON.parse(text)	
#	puts h.inspect()
	h["results"].each do |res|
	  	hh = Hash.new 	
		date = res["created_at"]
		hh["date"] =DateTime.parse(date)	
		#puts hh["date"]

		hh["from_user"] = res["from_user"]	
		#puts hh["from_user"]

		hh["from_user_id"] = res["from_user_id_str"]
		#puts hh["from_user_id"]

		hh["twit_id"] = res["id_str"]	
		puts hh["twit_id"]
			
		hh["twit"] = res["text"]
#		puts hh["twit"]

		if res["metadata"].has_key?("recent_retweets") == true
			hh["retwit_count"] = res["metadata"]["recent_retweets"]
		else
			hh["retwit_count"] = 0
		end	
#		puts hh["retwit_count"] 
		hh["cat"] = cat
		hh["kw"]	 = kw	
		puts "------"	
		save_content(hh)
	end
end



fetch_type("restaurant")
fetch_type("real_estate")

#search_twits("eat out")
#url="http://search.twitter.com/search.json?rpp=100&result_type=popular&include_entities=true&q="

