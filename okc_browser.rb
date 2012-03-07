class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/" do
    q = "
      SELECT username FROM profiles
    "
    db = SQLite3::Database.new "okcupid_browser.db"
    @usernames = db.execute(q).map &:pop
    erb :index
  end
end
