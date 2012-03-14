require "rubygems"
require 'bundler'

Bundler.require

# Classes
require "#{File.expand_path(File.dirname(__FILE__))}/ok_cupid.rb"

# Database Login
DB = SQLite3::Database.new( "#{File.expand_path(File.dirname(__FILE__))}/../db/okcupid.db" )

DB.execute("CREATE TABLE IF NOT EXISTS profiles (username varchar(128)  NOT NULL  PRIMARY KEY,`last_fetch_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,location Varchar(128) DEFAULT NULL,sex Varchar(16),age INTEGER,orientation Varchar(64),status Varchar(64))")
DB.execute("CREATE TABLE IF NOT EXISTS pictures (username varchar(128)  NOT NULL,size varchar(32) NOT NULL,url varchar(256) NOT NULL)")

@ok = OkCupid.new

raise "Unable to continue, login failed" unless @ok.login

MAX_PROFILES = 2000
STEP = 500
def fetch_usernames
  newbs = 0
  dups = 0
  @ok.match_usernames(MAX_PROFILES, STEP).each do |username|
    begin
      q = "INSERT INTO `profiles` (username) VALUES ('#{username}')"
      DB.execute q
      newbs += 1
    rescue Exception => e
      if e.to_s.include? "not unique"
        dups += 1
      else
        puts "#{q} FAILED: #{e}"
      end
    end
  end
  
  puts "Added #{newbs} items and found #{dups} duplicates"
end


def fetch_profile_pics
  # Find Users who we do not have any pictures for yet.
  # We can do a refresh some other time.
  q = "
    SELECT username FROM `profiles` 
    WHERE username NOT IN (SELECT DISTINCT username from `pictures`)
  "
  usernames = DB.execute(q).map(&:pop)
  puts "Fetching #{usernames.size} profiles' pictures... (estimated: #{usernames.size*3} pictures)"
  usernames.each_with_index do |username,index|
    puts "#{index}/#{usernames.size} completed" if 0 == index % 100
    profile = @ok.profile_pics_for username
    
    profile.each do |size,images|
      images.each do |url|
        begin
          q = "INSERT INTO `pictures` (username,url,size) 
                VALUES ('#{username}','#{url}','#{size}')"
          DB.execute q
        rescue Exception => e
          puts "Failed to #{q}; #{e}"
        end
      end
    end
  end
end

def update_profile_details
  q = "SELECT username FROM `profiles` WHERE location IS NULL OR location = ''"
  usernames = DB.execute(q).map(&:pop)
  puts "Updating #{usernames.size} profiles"
  usernames.each_with_index do |username,index|
    puts "#{index}/#{usernames.size} completed" if 0 == index % 100
    p = @ok.profile_for username
    p[:location] = p[:location].gsub("'","''") if p[:location]
    begin
      qr = "REPLACE INTO profiles (username,sex,age,orientation,status,location)
            VALUES ('#{username}',
                    '#{p[:sex]}',
                    '#{p[:age]}',
                    '#{p[:orientation]}',
                    '#{p[:status]}',
                    '#{p[:location]}'
            )"
      DB.execute qr
    rescue Exception => e
      puts "Failed to #{qr}; #{e}"
    end
  end
end


def download_pictures
  hydra = Typhoeus::Hydra.new(:max_concurrency => 10) # keep from killing some servers
  
  q = "SELECT username,size,url FROM `pictures` LIMIT 40"
  pictures = DB.execute(q)
  puts "#{pictures.size} to process"
  
  pictures.each do |picture|
    username = picture[0]
    size = picture[1]
    url = picture[2]

    filename = "#{username}_#{url.split('/').last}"
    download_directory = "../public/profile_pictures/#{size}/"
    if File.exists? download_directory + filename
      puts "SKIP: #{filename}"
      next
    else
      puts "FETCH: #{filename}"
    end

    request = Typhoeus::Request.new(url)
    request.on_complete do |response|
      File.open(download_directory + filename,"w+") do |f|
        f.write response.body
      end
    end

    hydra.queue request
  end
  
  hydra.run
end


case ARGV[0]
  when "usernames" then fetch_usernames
  when "pictures" then fetch_profile_pics
  when "profile_data" then update_profile_details
  when "update_db" then fetch_usernames; fetch_profile_pics; update_profile_details
  when "download_pictures" then download_pictures
  else puts "Usage: ruby scraper.rb [usernames|pictures|profile_data|update_db|download_pictures]"
end
