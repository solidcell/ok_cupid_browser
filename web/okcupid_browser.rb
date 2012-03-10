class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/pics" do
    content_type :json
    get_users(42, params[:last]).to_json
  end

  get "/" do
    @users = get_users(42)
    erb :index
  end

  private

  def get_users(count=42, offset=0)
    q = "SELECT username, url
         FROM pictures
         WHERE size = 'small'
         ORDER BY username
         LIMIT #{count.to_i}
         OFFSET #{offset.to_i}
        "
    db = SQLite3::Database.new "#{ROOT_PATH}/db/okcupid.db"
    db.execute(q)
  end
end
