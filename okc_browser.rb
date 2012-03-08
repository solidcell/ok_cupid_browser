class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/" do
=begin
    q = "
      SELECT username FROM profiles
    "
    db = SQLite3::Database.new "okcupid_browser.db"
    @users = {}
    db.execute(q).each do |username|
      username = username.pop
      paths = Dir.glob("public/profile_pictures/#{username}_*")
      paths = paths.map {|path| path.gsub "public/", ""}
      @users[username] = paths if paths.any?
    end
=end
    erb :index
  end
end
