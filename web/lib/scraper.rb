require "rubygems"
require 'bundler'

Bundler.require

# Classes
require "#{File.expand_path(File.dirname(__FILE__))}/ok_cupid.rb"

# Database Login
DB = SQLite3::Database.new( "#{File.expand_path(File.dirname(__FILE__))}/../db/okcupid.db" )

db_queries = [
  "CREATE TABLE IF NOT EXISTS profiles (
    username varchar(128) NOT NULL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    location Varchar(128) DEFAULT NULL,
    sex Varchar(16),
    age INTEGER,
    orientation Varchar(64),
    body_type Varchar(64),
    status Varchar(64) )",
  "CREATE TABLE IF NOT EXISTS pictures (
    username varchar(128) NOT NULL,
    size varchar(32) NOT NULL,
    url varchar(256) NOT NULL)",
  "CREATE TABLE IF NOT EXISTS raw_profiles (
    username varchar(128) NOT NULL,
    page TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
  "PRAGMA encoding = 'UTF-8'"
].each { |query| DB.execute query }

@ok = OkCupid.new
@ok.login or raise "Unable to continue, login failed"

MAX_PROFILES = 2000
STEP = 500
def fetch_usernames
  newbs = 0
  dups = 0
  @ok.match_usernames(MAX_PROFILES, STEP).each do |username|
    begin
      q = "INSERT INTO `profiles` (username) VALUES (?)"
      DB.execute(q,username)
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
    SELECT username
    FROM `profiles`
    WHERE username NOT IN (SELECT DISTINCT username FROM `pictures`)
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
               VALUES (?,?,?)"
          DB.execute(q,username,url,size)
        rescue Exception => e
          puts "Failed to #{q}; #{e}"
        end
      end
    end
  end
end

def fetch_profile_details
  q = "
    SELECT username
    FROM `profiles`
    WHERE username NOT IN (SELECT DISTINCT username FROM `raw_profiles`)
    LIMIT 100
  "
  usernames = DB.execute(q).map(&:pop)
  puts "Fetching #{usernames.size} profile pages"

  usernames.each_with_index do |username,index|
    puts "#{index}/#{usernames.size} completed" if 0 == index % 100
    begin
      qr = "INSERT INTO raw_profiles (username,page) VALUES (?,?)"
      DB.execute(qr,username,@ok.profile_page(username).body)
    rescue Exception => e
      puts "Failed to #{qr}; #{e}"
    end
  end
end

# Process Raw Profiles out of the SQL Database
# For each Page load it into Nokogiri::HTML
# And extract the data desired, loading it back into the profiles table
def process_raw_profiles rate = 100

  count = DB.execute("SELECT count(0) from raw_profiles").flatten[0].to_i
  puts "Updating #{count} profiles"
  
  pages = count/rate
  (count/rate+1).times do |iteration|
    q = "SELECT username,page FROM `raw_profiles` LIMIT #{rate} OFFSET #{rate*iteration}"
    raw_profiles = DB.execute(q)
    raw_profiles.each_with_index do |row,index|
      puts "#{index}/#{raw_profiles.size} completed" if 0 == index % 100
      next unless p = @ok.profile_for(row.first,Nokogiri::HTML(row.last))
      begin
        qr = "REPLACE INTO profiles (username,sex,age,orientation,status,location,body_type) VALUES (?,?,?,?,?,?,?)"
        DB.execute(qr,row.first,p[:sex],p[:age],p[:orientation],p[:status],p[:location],p[:body_type])
      rescue Exception => e
        puts "Failed to #{qr}; #{e}"
      end
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

def do_it_all
  fetch_usernames
  fetch_profile_pics
  fetch_profile_details
  process_raw_profiles
end

########################-------------------------#######################

targets = {
  "fetch_usernames" => "Fetch Match Usernames and store to SQL",
  "fetch_profile_pics" => "Fetch profile pic URLS and store to SQL",
  "fetch_profile_details" => "Fetch profile pages and store them to SQL",
  "process_raw_profiles" => "Process the raw profile pages stored in SQL",
  "do_it_all" => "Fetch all data and process it (Hits Internet)",
  "download_pictures" => "For the stored profile pics in SQL, download the raw files"
}

if targets.keys.include? ARGV[0]
  self.send ARGV[0]
else
  puts "Usage: ruby scraper.rb command"
  puts "The support commenads are as follows:"
  targets.each { |k,v| puts "#{k} [#{v}]" }
end
