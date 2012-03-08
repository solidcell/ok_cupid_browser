class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/" do
    q = "SELECT username, url FROM pictures WHERE size = 'small' GROUP BY username"
    db = SQLite3::Database.new "db/okcupid.db"
    @users = db.execute(q)

    erb :index
  end
end
