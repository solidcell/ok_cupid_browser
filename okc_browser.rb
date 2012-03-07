class OKCBrowser < Sinatra::Base
  set :erb, :format => :html5

  get "/" do
    erb :index
  end
end
