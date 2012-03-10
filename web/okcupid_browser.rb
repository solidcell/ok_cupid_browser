class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/pics" do
    content_type :json
    get_users(42, params[:last],params[:loc]).to_json
  end

  get "/" do
    db = SQLite3::Database.new "#{ROOT_PATH}/db/okcupid.db"
    @locations = db.execute("SELECT DISTINCT location FROM profiles")
    @locations = @locations.flatten(1).reject {|x| x.empty? }
    @users = get_users(42,0,params[:loc])
    erb :index
  end

  private

  def get_users(count=42, offset=0,location="All")
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
