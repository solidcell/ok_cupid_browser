class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/pics" do
    content_type :json
    paths = Dir.entries("public/profile_pictures/small")[2..-1]
    paths = paths[params[:last].to_i, 10]
    paths = paths.map do |path|
      {
        "Image_URL" => "profile_pictures/small/#{path}",
        "Profile_URL" => "http://www.okcupid.com/profile/some_username"
      }
    end
    paths.to_json
  end

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
