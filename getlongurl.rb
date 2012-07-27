require 'rubygems'
require 'httpclient'
require 'mysql'

# this script expand twitter urls and find matches in news link table.


def  expandurl(new_u)
	#u = "http://t.co/NdcLtl1H"
	i = 0
	begin
		client = HTTPClient.new
		while ( new_u != nil) and (i < 10)
			result = client.head(new_u)
			u = new_u
			new_u = result.header['Location'][0]
			puts u
			i = i+1
		end
	rescue Exception => e
		puts "err in expanding url..."
		return 
	end 	
	return u
end




def scan_twits_since(id)
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
	     res = db.query("select * from twits where id > #{id} limit 1000 ")
		while trow = res.fetch_hash do
			t = trow["twit"]
			puts "id : #{trow["id"]}"	
			t.match( /(http:\/\/t\.co\/[^ ]*)/) do |m|
#				puts m
				lm =expandurl(m)
				puts lm
				count=0
				if lm != nil
			     	res1 = db.query("select * from data where link like \"%#{lm}%\" ")
					count=res1.num_rows
					twited = trow["retwit_count"].to_i + 1
					if count >0
						while rowx = res1.fetch_hash do
							id=rowx["id"]
							puts "updating for id = #{id}"	
							result = db.query("UPDATE data SET twited=twited+#{twited} WHERE id=#{id}") 			    	
						end
					else
						#twit url not found insert it ....
						link = lm.to_s
						title = 	t
						adate = trow["date"]	
						twited = trow["retwit_count"].to_i + 1
						cat = trow["cat"]
						kw = trow["kw"]
						source = "twitter"
						desc = ""	
						puts "inserting afresh..."	
						begin
							db.query("INSERT INTO data ( `link`,`title`,`date`,`source`,`twited`,`cat`,`kw`,`desc` ) VALUES ('#{db.escape_string(link)}','#{db.escape_string(title)}','#{adate}','#{source}',#{twited},'#{cat}','#{kw}','#{db.escape_string(desc)}') ")
						rescue Mysql::Error => e
						     puts "Error code: #{e.errno}"
						     puts "Error message: #{e.error}"
						     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
						end								
					end
					puts "found=#{count}"
			     end
			end
			#save last id from twit table
			File.open(File.dirname(__FILE__)+"/"+"last_twit_id" , 'w') {|f| f.write(trow["id"]) }
#			puts t
		end
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end	
return 1
end




# fetch and process until the last id is not increasing in every iteration. (no knew data or error)

#puts  expandurl("http://t.co/NdcLtl1H")
last_id =0
begin
	prev_last_id = last_id
	begin
		last_id = File.read(File.dirname(__FILE__)+"/"+"last_twit_id").to_i
	rescue Exception => e
		last_id =1
	end
	puts "resuming from id #{last_id}..."
	scan_twits_since(last_id)
end while (last_id > prev_last_id)

#end

