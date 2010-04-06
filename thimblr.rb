require 'rubygems'
gem 'sinatra'
require 'sinatra'
require 'erb'
require 'thimblr_parser'
require 'json'
require 'digest/md5'

# TODO: Make this more robust
s = YAML::load(open("settings.yaml"))
set :editor, s['Editor'] if s['Editor']
set :themes, File.expand_path((File.directory? s['ThemesLocation']) ? s['ThemesLocation'] : "./themes")
set :data, File.expand_path((File.directory? s['DataLocation']) ? s['DataLocation'] : "data")
set :allowediting, (s['AllowEditing'] == true) ? true : false
set :tumblr, Thimblr::Parser::Defaults.merge(s['Tumblr'])

enable :sessions
set :bind, '127.0.0.1'
set :port, 4567

get '/' do
  erb :index
end

get '/help' do
  erb :help
end

get %r{/set/theme/([\w-]+)} do |theme|
  file = "#{settings.themes}/#{theme}.html"
  if File.exists?(file)
    puts "Setting Theme as #{theme}"
    response.set_cookie('theme',theme)
  else
    puts "Didn't on #{file}"
    halt 404, "Not found"
  end
end

get '/themes.json' do
  themes = {}
  Dir.glob("#{settings.themes}/*.html").collect do |theme|
    themes[File.basename(theme,".html")] = Digest::MD5.hexdigest(open(theme).read)
  end
  themes.to_json
end

get %r{/set/data/([\w-]+)} do |data|
  file = "#{settings.data}/#{data}.yml"
  if File.exists?(file)
    response.set_cookie('data',data)
  else
    halt 404, "Not found"
  end
end

get '/data.json' do
  data = {}
  Dir.glob("#{settings.data}/*.yml").collect do |datum|
    data[File.basename(datum,".yml")] = Digest::MD5.hexdigest(open(datum).read)
  end
  data.to_json
end


get %r{^/edit/(theme|data)$} do |file|
  halt 403, "Forbidden" if !settings.allowediting
  
  case file
  when 'theme'
    filename = "#{settings.themes}/#{request.cookies['theme']}.html"
  when 'data'
    filename = "#{settings.data}/#{request.cookies['data'] }.yml"
  else
    halt 400, "Not a valid edit selection"
  end
  if File.exists? filename
    # TODO: Send useful http status response
    `#{settings.editor} "#{filename}"`
  else
    halt 404, "Odd, I can't find that file"
  end
end

# Downloads feed data from a tumblr site
get %r{/download/data/([a-zA-Z-]+)} do
  
end

before do
  request.cookies['data'] ||= "demo"
  if request.env['REQUEST_PATH'] =~ /^\/thimblr/
    if File.exists?("#{settings.themes}/#{request.cookies['theme']}.html")
      @parser = Thimblr::Parser.new("#{settings.data}/#{request.cookies['data']}.yml","#{settings.themes}/#{request.cookies['theme']}.html")
    else
      redirect '/help'
    end
  end
end

# The index page
get %r{^/thimblr(?:/page/(\d+))?/?$} do |pageno|
  @parser.render_posts((pageno || 1).to_i)
end

# An individual post
get %r{^/thimblr/post/(\d+)/?.*$} do |postid|
  @parser.render_permalink(postid)
end

get %r{^/thimblr/search/(.+)$} do |query|
  @parser.render_search(query)
end

get %r{^/thimblr/tagged/(.+)$} do |tags|
  halt 501, "Not Implemented"
end

# Protected page names that shouldn't go to pages and aren't implemented in Thimblr
get %r{^/thimblr/(?:rss|archive)$} do 
  halt 501, "Not Implemented"
end

# This is for pages
get '/thimblr/*' do
  p "This is a page"
  @parser.render_page(params[:splat])
end