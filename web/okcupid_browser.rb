require 'sinatra/base'
require 'sinatra/session'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

class OKCBrowser < Sinatra::Base
  set :environment, :development
  register Sinatra::Session

  set :session_fail, '/pass'
  set :session_secret, 'S00P3R5faaaaab'
  SECRET_CODE = "findmeone"
  
  set :erb, :format => :html5, :encoding => 'utf-8'

  get "/" do
    session!
    
    db = SQLite3::Database.new "#{ROOT_PATH}/db/okcupid.db"
    q = "SELECT DISTINCT location FROM profiles ORDER BY location ASC"
    @locations = []
    locs = db.execute(q).each do |l|
      next if l.nil?
      e = l.first.force_encoding('UTF-8')
      @locations << e unless e.empty?
    end

    @users = get_users(42,0,params[:loc])
    erb :index
  end

  get "/pass" do
    if session?
      redirect '/'
    else    
      erb :pass
    end
  end

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

  get "/pics" do
    session!
    
    content_type :json
    get_users(42, params[:last],params[:loc]).to_json
  end

  private

  def get_users(count=42, offset=0, location="All")
    q = if location.nil? || location.empty? || location == "All"
      "SELECT username, url
         FROM pictures
         WHERE size = 'small'
         ORDER BY username
         LIMIT #{count.to_i}
         OFFSET #{offset.to_i}
        "
    else
      location = CGI::unescape(location).gsub("'","''")
      "SELECT pictures.username, pictures.url
         FROM pictures
         JOIN profiles on profiles.username = pictures.username
         WHERE size = 'small' AND location = '#{location}'
         ORDER BY pictures.username
         LIMIT #{count.to_i}
         OFFSET #{offset.to_i}
        "
    end

    db = SQLite3::Database.new "#{ROOT_PATH}/db/okcupid.db"
    db.execute(q)
  end
end
