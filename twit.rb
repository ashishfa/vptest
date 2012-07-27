require 'rubygems'
require 'twitter'
# sample code to test twitter gem..

#puts Twitter.user("ashishfa").location
rate_limit = Twitter.rate_limit
#puts "hi  iii "
puts rate_limit.remaining

Twitter.search("real estate",:lang => "en", :rpp => 10, :result_type => "mixed").results.map do |status|
        puts  "#{status.from_user}: "
        puts  "#{status.metadata.result_type}: "
        puts  "#{status.inspect}"
        puts "______"
         
#        if (status.metadata.has_key?("recent_retweets") == true )
#                puts "#{status.metadata.recent_retweets}"
#       end
end
