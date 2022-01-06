require 'json'
require 'rmagick'
require 'typhoeus'
include Magick

def thumb(source_image, geometry_string, radius = 10)
  source_image.change_geometry(geometry_string) do |cols, rows, img| 
    thumb = img.resize(cols, rows)
    mask = Image.new(cols, rows) { |img| img.background_color = 'transparent' }

    Draw.new
      .stroke('none').stroke_width(0).fill('white')
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

def fetch_user(username, bearer_token, params)
  users_url = "https://api.twitter.com/2/users/by/username/#{username}"

  options = {
    method: 'get',
    headers: {
      'User-Agent': 'v2ListLookupRuby',
      'Authorization': "Bearer #{bearer_token}"
    },
    params: params
  }

  request = Typhoeus::Request.new(users_url, options)
  response = request.run

  return response
end

bearer_token = ENV['BEARER_TOKEN']

usernames = [
  # Add your list of Twitter usernames here - automating this might follow
  # e.g. 'dhh', 'rubyonrails'
]

username_rows = each_alternating_slice(usernames, 7, 6)

img = Magick::Image.new(1200, 400) do |image|
  image.background_color = '#ffffff'
end

user_params = { 'user.fields': 'profile_image_url' }
start_y = 80

username_rows.each do |row|
  start_x = (1200 - (row.length * 75)) / 2

  row.each do |username|
    puts username
    response = fetch_user(username, bearer_token, user_params)
    user_data = JSON.parse(response.body)

    avatar_url = user_data['data']['profile_image_url']
    avatar_url = avatar_url.gsub('_normal', '_400x400')
    avatar_image = Magick::Image.read(avatar_url)
    thumbnail_image = thumb(avatar_image[0], '80x80', 39)
    img.composite!(thumbnail_image, start_x, start_y, Magick::OverCompositeOp)

    start_x += 75
  end

  start_y += 85
end

img.write("twitter_list_header.jpg")


