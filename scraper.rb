require "rubygems"
require 'base64'
require 'bundler'

Bundler.require

@agent = Mechanize.new
@agent.user_agent_alias = "Mac Safari"

page = @agent.get "http://www.okcupid.com/"

if page.body.include? "sidebar_signin_password"
  # login
  form = page.form_with :name => 'loginf'
  form.username = "i_like_lamps"
  form.password = Base64.decode64("anVua3lhcmQxOTg3Ng==\n")
  form.submit
end

# Database Login
DB = SQLite3::Database.new( "okcupid.db" )

DB.execute("CREATE TABLE IF NOT EXISTS `profiles` (
    `username` varchar(128) PRIMARY KEY,
    `last_fetch_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )")

filters = [
  "JOIN",
  "SPECIAL_BLEND"
]

MAX_PROFILES = 2000
STEP = 500
def fetch_usernames
  low = 1
  dupitydup = 0
  newpitynewps = 0

  (MAX_PROFILES/STEP).times do
    p = @agent.get "https://www.okcupid.com/match?timekey=1&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=#{low}&count=#{STEP}&ajax_load=1"

    usernames = p.body.scan(/usr-([_A-Za-z0-9]+)\\\"/i).each do |username|
      begin
        # call first on uid as nokogiri gives us an array with
        # the uid as the only element
        q = "INSERT INTO `profiles` (username) VALUES ('#{username.first}')"
        DB.execute q
        newpitynewps += 1
      rescue Exception => e
        if e.to_s.include? "is not unique"
          dupitydup += 1
        else
          puts "#{q} FAILED: #{e}"
        end
      end
    end
    low += STEP
  end

  puts "#{dupitydup} dupitydups"
  puts "#{newpitynewps} newpitynewps"
end

def fetch_profile_pics
=begin
  * Skip a user if we find a picture of them
  ** Eventually, we will want to do an update on current users we already have
  ** images stored for. But for now let's focus on new users only
=end

  puts "Fetching #{STEP} items at a time..."
  hydra = Typhoeus::Hydra.new(:max_concurrency => 15) # keep from killing some servers

  usernames = DB.execute("SELECT username FROM `profiles`")

  puts usernames.inspect

  exit
  usernames.each do |username|
    if Dir.glob("profile_pictures/#{username}_*").any?
      puts "SKIP: #{username} already, skipping"
      next
    else
      puts "FETCH: #{username}"
    end

    profile = @agent.get "https://www.okcupid.com/profile/#{username}/photos"
    profile.search("//div[@id='profile_thumbs']//img/@src").each do |img_tag|
      filename = "#{username}_#{img_tag.value.split('/').last}"
      stored_filename = "profile_pictures/#{filename}"

      next if File.exists? stored_filename

      request = Typhoeus::Request.new(img_tag.value)
      request.on_complete do |response|
        File.open(stored_filename,"w+") do |f|
          f.write response.body
        end
      end

      hydra.queue request
    end
  end

  hydra.run
end

fetch_usernames
# fetch_profile_pics
