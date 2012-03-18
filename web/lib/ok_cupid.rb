require 'base64'

class OkCupid
  attr_reader :username

  def initialize username = "i_like_lamps", password = Base64.decode64("anVua3lhcmQxOTg3Ng==\n")
    @agent = Mechanize.new
    @agent.user_agent_alias = "Mac Safari"
    @username = username
    @password = password
  end

  def login
    page = @agent.get "https://www.okcupid.com/"

    if page.body.include? 'name="loginf"'
      # login
      form = page.form_with :name => 'loginf'
      form.username = @username
      form.password = @password
      form.submit
    end

    page = @agent.get "https://www.okcupid.com/"

    !page.body.include? 'name="loginf"'
  end

  def get_url url = nil
    return false unless url

    @agent.get url
  end

  def hidden_profiles
    usernames = []

    low = 1
    page = 1
    loop do
      p = get_url "http://www.okcupid.com/hidden-users?low=#{low}"
      p.body.scan(/\/profile\/([_A-Za-z0-9]+)\"/).each do |username_array|
        usernames << username_array.first
      end
      num_pages ||= p.body.scan(/<a href="\/hidden-users\?low=\d+">(\d+)<\/a>/).last.first.to_i
      break unless page < num_pages
      page += 1
      low += 25
    end

    usernames.uniq
  end

  # filters = ["JOIN","SPECIAL_BLEND"]
  def match_usernames max_profiles = 2000, step = 500
    usernames = []

    low = 1
    (max_profiles/step).times do
      p = get_url "https://www.okcupid.com/match?timekey=1&matchOrderBy=SPECIAL_BLEND&use_prefs=1&discard_prefs=1&low=#{low}&count=#{STEP}&ajax_load=1"
      p.body.scan(/usr-([_A-Za-z0-9]+)\\\"/).each do |username_array|
        usernames << username_array.first
      end

      low += step
    end

    usernames.uniq
  end

  def profile_page username
    return false unless username
    get_url "http://m.okcupid.com/profile/#{username}"
  end

  def profile_for username = nil, parsed_profile = nil
    profile = parsed_profile || profile_page(username)

    # Watch out for profiles that have been deleted!
    return false if profile.inner_html.include?("have a user by that name!")

    # Age, Sex, Orientation
    aso = profile.search("//p[@class='aso']").inner_text.split(/\s\/\s/)

    # Location
    location = profile.search("//p[@class='location']").inner_text

    # Body Type
    btype_elem = profile.search("//span[contains(text(),'Body Type')]").first
    body_type = btype_elem.next_element.inner_text

    {
      :username => username,
      :age => aso[0],
      :sex => aso[1],
      :orientation => aso[2],
      :status => aso[3],
      :location => location,
      :body_type => body_type
    }
  end

  def profile_pics_for username = nil
    return false unless username
    profile = get_url "https://www.okcupid.com/profile/#{username}/photos"

    pic_thumbs = profile.search("//div[@id='profile_thumbs']//img/@src").map(&:value)
    pic_fulls = profile.search("//div[@class='img']//img/@src").map(&:value)

    {
      :small => pic_thumbs,
      :big => pic_fulls
    }
  end
end
