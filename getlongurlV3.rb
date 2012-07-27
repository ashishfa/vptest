require 'rubygems'
require 'httpclient'
require 'mysql' 

require '/home/ashish/rubycode/contentcat/thread-pool' 
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



# scan twits and if it has a link which is in data table increment its retwited count 
def scan_twits_since(id,l)
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
#	     puts "Server version: " + db.get_server_info
	     res = db.query("select * from twits where id > #{id}  and id <= #{id+l} ")
		while trow = res.fetch_hash do
			process_twit(trow)
		end
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end
	db.close()	
return 1
end




# process a twit entry at a time
def process_twit(twit_entry)

	trow = twit_entry
	db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
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
					File.open(File.dirname(__FILE__)+"/"+"logurl.log" , 'a') {|f| f.write("for twit:#{trow["id"]}:updating for id = #{id}\n") }	
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
				File.open(File.dirname(__FILE__)+"/"+"logurl.log" , 'a') {|f| f.write("for twit:#{trow["id"]}:inserting afresh...\n") }
				begin
					db.query("INSERT INTO data  ( `link`,`title`,`date`,`source`,`twited`,`cat`,`kw`,`desc` ) VALUES ('#{db.escape_string(link)}','#{db.escape_string(title)}','#{adate}','#{source}',#{twited},'#{cat}','#{kw}','#{db.escape_string(desc)}') ")
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
#	File.open(File.dirname(__FILE__)+"/"+"last_twit_id" , 'w') {|f| f.write(trow["id"]) }
	db.close()	
#			puts t
end#




#fetch id of latest fetched twit  
def get_last_id()
	begin
		db =  Mysql.real_connect('localhost', 'ashish', 'ashish', 'content')
		res = db.query("select max(id) as m_id from twits")
		cc = -1
		while row = res.fetch_hash do
			cc = row["m_id"]
		end
	rescue Mysql::Error => e
	     puts "Error code: #{e.errno}"
	     puts "Error message: #{e.error}"
	     puts "Error SQLSTATE: #{e.sqlstate}" if e.respond_to?("sqlstate")
	end			
	return cc
end#



puts 
puts

# fetch and process until the last id crosses the current max id 
begin
	last_id = File.read(File.dirname(__FILE__)+"/"+"last_twit_id_scanned").to_i
	puts "#{Time.new} : started with last id :#{last_id}" 
	limit=100
	thr=10
	p = Pool.new(thr)
	maxid = (get_last_id).to_i
	puts "max id is : #{maxid}"
	while last_id < maxid
		p.schedule(last_id,limit) { |id,l| 
			scan_twits_since(id,l)
			puts "working form #{id}...#{id+l}"
		}
		last_id = last_id + limit
#		puts "last_id = #{last_id}"
	end
#	puts "last_id = #{last_id}"
	if last_id > maxid
		mm = maxid
	else
		mm = last_id
	end
	at_exit { p.shutdown }
	File.open(File.dirname(__FILE__)+"/"+"last_twit_id_scanned" , 'w') {|f| f.write(mm) }
	puts "lastid = #{last_id}"
	puts "#{Time.new} : ended with last id :#{mm}" 
rescue Exception => e
     puts "Error "
end

# 173065


