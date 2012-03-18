require 'sinatra/base'
require 'sinatra/session'
require "sinatra/reloader"

require "#{File.expand_path(File.dirname(__FILE__))}/includes/initializer.rb"

# Application Settings
ALLOWED_FILTERS = %w(location sex age body_type status)
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
    register Sinatra::Reloader
  end

  # Setup Session controls
  register Sinatra::Session
  set :session_fail, '/pass'
  set :session_secret, 'S00P3R5faaaaab'

  # Standard HTML Responses
  set :erb, :format => :html5, :encoding => 'utf-8'

  # Index
  get "/" do
    session!

    @locations  = get_values_from_column :location
    @body_types = get_values_from_column :body_type

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
    redirect '/' if session?

    erb :pass
  end

  # Check Password
  post "/pass" do
    if params[:code] && 'findmeone' == params[:code]
      session_start!
      session[:valid] = true
      redirect '/'
    else
      redirect '/pass'
    end
  end

  get '/logout' do
    session_end!(destroy=true)

    redirect '/'
  end

  private

  def get_values_from_column column
    conditions = case column
                   when :location then "AND location LIKE '%CALIFORNIA%'"
                 end

    Database.new.db_execute(
      "SELECT DISTINCT #{column}
        FROM profiles
        WHERE #{column} NOT NULL AND #{column} != '' #{conditions}
        ORDER BY #{column} ASC"
    ).map { |result_array| result_array.first.force_encoding("UTF-8") }
  end

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
      if params.has_key?(filter_name) && "All" != params[filter_name]
        filter_string += " AND #{filter_name} LIKE ?"
        prepared_filters << params[filter_name]
      end
    end

    # If no user filters provided we will defalt to California
    filter_string = "AND location LIKE '%CALIFORNIA%'" if filter_string.empty?

    prepared_filters << count.to_i
    prepared_filters << offset.to_i
    
    # Connect to the database
    Database.new.db_execute(
      "SELECT pictures.username, 
        pictures.url, 
        profiles.created_at, 
        profiles.location
      FROM pictures
      JOIN profiles ON profiles.username = pictures.username
      WHERE size = 'small' #{filter_string}
      ORDER BY profiles.created_at DESC
      LIMIT ? OFFSET ?",
      prepared_filters
    )
  end

end
