require 'sinatra/base'
require 'sinatra/session'

# Strict Encoding Defaults
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class OKCBrowser < Sinatra::Base
  
  # Default to Development Environment
  # Include the Sinatra/Reloader so we don't
  # have to restart the web server for every code change
  if ENV['SIN_MODE'] == "production"
    set :environment, :production
  else
    set :environment, :development
    require "sinatra/reloader"
  end

  # Setup Session controls
  register Sinatra::Session
  set :session_fail, '/pass'
  set :session_secret, 'S00P3R5faaaaab'
  SECRET_CODE = 'findmeone'

  # Standard HTML Responses
  set :erb, :format => :html5, :encoding => 'utf-8'

  # Index
  get "/" do
    session!

    db = SQLite3::Database.new "#{ROOT_PATH}/db/okcupid.db"
    q = "SELECT DISTINCT location FROM profiles WHERE location LIKE '%CALIFORNIA%' ORDER BY location ASC"
    @locations = []
    locs = db.execute(q).each do |l|
      next if l.nil?
      e = l.first.force_encoding('UTF-8')
      @locations << e unless e.empty?
    end

    @users = get_users(42,0)
    erb :index
  end
  
  # Browse Pictures
  get "/pics" do
    session!

    content_type :json
    get_users(42, params[:last]).to_json
  end


  # Ask for Password
  get "/pass" do
    if session?
      redirect '/'
    else
      erb :pass
    end
  end

  # Check Password
  post "/pass" do
    puts params.inspect
    if c = params[:code]
      if SECRET_CODE == c
        session_start!
        session[:valid] = true
      end
      redirect '/'
    else
      redirect '/pass'
    end
  end
  
  private
  
  
  ALLOWED_FILTERS = %w(location sex age body_type status)
  
  # This method uses the global params object
  # in conjunction with the ALLOWED_FILTERS constant
  # to identify the filters a user might want to use
  # and returns the user profiles and pictures from the db
  def get_users(count=42, offset=0)
    # Build a Filter String with a corresponding array of
    # prepared filters for the sql execution
    # (prepared statements prevent sql injection)
    prepared_filters = []
    filter_string = ""
    
    ALLOWED_FILTERS.each do |filter_name|
      if params.has_key?(filter_name)
        filter_string += " AND #{filter_name} LIKE ?"
        prepared_filters << params[filter_name]
      end
    end
    
    # If no user filters provided we will defalt to California
    filter_string = "AND location LIKE '%CALIFORNIA%'" if filter_string.empty?

    # Build our final Query, respecting any offsets
    q_final = "
      SELECT pictures.username, pictures.url, profiles.last_fetch_date, profiles.location
      FROM pictures
      JOIN profiles on profiles.username = pictures.username
      WHERE size = 'small'
      #{filter_string}
      ORDER BY profiles.last_fetch_date DESC
      LIMIT #{count.to_i}
      OFFSET #{offset.to_i}
    "

    puts q_final
    
    # Connect to the database
    db = SQLite3::Database.new("#{ROOT_PATH}/db/okcupid.db")
    
    # Execute the query and return the result
    if prepared_filters.any?
      puts "User Filters are being used. Values for SQL -> #{prepared_filters.inspect}"
      db.execute(q_final,*prepared_filters)
    else
      db.execute(q_final)
    end
  end

  # a handy debug method that only prints in non production environments
  def puts msg
    if settings.environment != :production
      super(msg)
    end
  end
  
end
