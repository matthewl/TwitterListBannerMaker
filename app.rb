require 'rmagick'
require 'oauth'
require 'json'
require 'typhoeus'
require 'oauth/request_proxy/typhoeus_request'
include Magick

class ListMember < Struct.new(:username, :profile_image_url)
  def <=>(other)
    self[:username] <=> other[:username]
  end
end

# Set the consumer key and secret of your Twitter application here.
consumer_key = ENV['CONSUMER_KEY']
consumer_secret = ENV['CONSUMER_SECRET']

consumer = OAuth::Consumer.new(
  consumer_key, consumer_secret,
  site: 'https://api.twitter.com',
  authorize_path: '/oauth/authenticate',
  debug_output: false
)

@list_names = []
@list_ids = []
@max_list = 0
@warning_message = ''

def get_request_token(consumer)
  request_token = consumer.get_request_token()

  return request_token
end

def get_user_authorization(request_token)
  puts "Follow this URL to have a user authorize your app: #{request_token.authorize_url()}"
  puts 'Enter PIN: '
  pin = gets.strip

  return pin
end

def obtain_access_token(consumer, request_token, pin)
  token = request_token.token
  token_secret = request_token.secret
  hash = { oauth_token: token, oauth_token_secret: token_secret }
  request_token = OAuth::RequestToken.from_hash(consumer, hash)

  # Get access token
  # TODO: Can we stash these tokens in a file for later?
  access_token = request_token.get_access_token({ oauth_verifier: pin })

  return access_token
end

def build_request(url, options, oauth_params)
  request = Typhoeus::Request.new(url, options)
  oauth_helper = OAuth::Client::Helper.new(request, oauth_params.merge(request_uri: url))
  request.options[:headers].merge!({ 'Authorization' => oauth_helper.header }) # Signs the request

  return request
end

def thumb(source_image, geometry_string, radius = 10)
  source_image.change_geometry(geometry_string) do |cols, rows, img|
    thumb = img.resize(cols, rows)
    mask = Image.new(cols, rows) { |img| img.background_color = 'transparent' }

    Draw.new
      .stroke('none')
      .stroke_width(0)
      .fill('white')
      .roundrectangle(0, 0, cols - 1, rows - 1, radius, radius)
      .draw(mask)

    thumb.composite!(mask, 0, 0, Magick::CopyAlphaCompositeOp)
    thumb
  end
end

def each_alternating_slice(array, initial_size, alternate_size)
  alternated_array = []
  size = initial_size

  while array.length > 0
    alternated_array << array.slice!(0, size)

    if size == initial_size
      size = alternate_size
    else
      size = initial_size
    end
  end

  alternated_array
end

def fetch_me(oauth_params)
  url = 'https://api.twitter.com/2/users/me'

  options = {
    method: :get,
    headers: {
      'User-Agent': 'TwitterListBannerMaker',
      'content-type': 'application/json'
    },
    params: {}
  }

  request = build_request(url, options, oauth_params)
  response = request.run

  return response
end

def fetch_lists(user_id, oauth_params)
  url = "https://api.twitter.com/2/users/#{user_id}/owned_lists"

  options = {
    method: :get,
    headers: {
      'User-Agent': 'TwitterListBannerMaker',
      'content-type': 'application/json'
    },
    params: {}
  }

  request = build_request(url, options, oauth_params)
  response = request.run

  return response
end

def fetch_list_members(list_id, oauth_params)
  url = "https://api.twitter.com/2/lists/#{list_id}/members"

  options = {
    method: :get,
    headers: {
      'User-Agent': 'TwitterListBannerMaker',
      'content-type': 'application/json'
    },
    params: { 'user.fields': 'profile_image_url' }
  }

  request = build_request(url, options, oauth_params)
  response = request.run

  return response
end

def display_menu(message = '')
  puts ''
  puts 'Enter the number of the list you want to use for the banner :'
  puts '-------------------------------------------------------------'
  puts ''

  @list_names.each_with_index do |list, index|
    puts "#{index + 1}. #{list}"
    @max_list = index
  end

  puts ''
  puts "Or enter 'q' to quit"
  
  if @warning_message != ''
    puts ''
    puts @warning_message
  end

  puts ''
  puts 'List number: '
end

def generate_banner_for_list(list_number)
  if list_number.to_i > @max_list
    @warning_message = 'Invalid list number. Please try again.'
  else
    list_id = @list_ids[list_number.to_i - 1]

    # Get the users on that list
    response = fetch_list_members(list_id, @oauth_params)
    members_data = JSON.parse(response.body)
    list_members = []

    members_data['data'].each do |member|
      list_members << ListMember.new(member['username'], member['profile_image_url'])
    end

    list_members.sort

    img = Magick::Image.new(1200, 400) do |image|
      image.background_color = '#ffffff'
    end

    # TODO: Configure the layout to adjust to different sizes of list.
    # TODO: Add a maximum number of members to display.

    start_y = 80
    list_member_rows = each_alternating_slice(list_members, 8, 6)

    list_member_rows.each do |row|
      start_x = (1200 - (row.length * 75)) / 2

      row.each do |list_member|
        profile_image = Magick::Image.read(list_member.profile_image_url.gsub('_normal', '_400x400'))
        rounded_profile_image = thumb(profile_image[0], '80x80', 39)
        img.composite!(rounded_profile_image, start_x, start_y, Magick::OverCompositeOp)

        start_x += 75
      end

      start_y += 85
    end

    img.write("twitter_list_#{list_id}_header.jpg")
    @warning_message = ''
  end
end

# PIN-based OAuth flow - Step 1
request_token = get_request_token(consumer)

# PIN-based OAuth flow - Step 2
pin = get_user_authorization(request_token)

# PIN-based OAuth flow - Step 3
access_token = obtain_access_token(consumer, request_token, pin)
@oauth_params = { consumer: consumer, token: access_token }

# Get lists for account
user = fetch_me(@oauth_params)
user_id = JSON.parse(user.body)['data']['id']
response = fetch_lists(user_id, @oauth_params)
list_data = JSON.parse(response.body)

# TODO: Create a single array to store list data
list_data['data'].each do |list|
  @list_ids << list['id']
  @list_names << list['name']
end

puts 'Welcome to TwitterListBannerMaker! 😀'

loop do
  display_menu(@warning_message)
  input = gets.strip

  # TODO: Add an option to generates images for all lists.

  case input
  when /\d/i
    generate_banner_for_list(input)
  when 'q'
    break
  else puts 'Invalid option'
  end
end
