require 'rubygems'
require 'sinatra'
require 'json'
require 'digest/md5'
require 'pathname'
require 'launchy'
require 'thimblr/parser'
require 'rbconfig'

class Thimblr::Application < Sinatra::Application
  Editors = {
    'textmate' => {'command' => "mate",'platform' => "mac",'name' => "TextMate"},
    'bbedit'   => {'command' => "bbedit",'platform' => 'mac','name' => "BBEdit"},
    'textedit' => {'command' => "open -a TextEdit.app",'platform' => 'mac','name' => "TextEdit"}
  }
  Locations = [
    {"dir" => "~/Library/Application Support/Thimblr/", 'name' => "Application Support", 'platform' => "mac"},
    {'dir' => "~/.thimblr/",'name' => "Home directory", 'platform' => "nix"}
  ]
  
  case RbConfig::CONFIG['target_os']
  when /darwin/i
    Platform = "mac"
  when /mswin32/i
    Platform = "win"
  else
    Platform = "nix"
  end
  
  def self.parse_config(s)
    set :themes, File.expand_path((File.directory? s['ThemesLocation']) ? s['ThemesLocation'] : "./themes")
    set :data, File.expand_path((File.directory? s['DataLocation'] || "") ? s['DataLocation'] : "")
    set :allowediting, (s['AllowEditing']) ? true : false
    set :editor, s['Editor'] if s['Editor']
    set :tumblr, Thimblr::Parser::Defaults.merge(s['Tumblr'] || {})
    set :port, (s['Port'].to_i > 0) ? s['Port'].to_i  : 4567
  end
  
  configure do |s|
    set :root, File.join(File.dirname(__FILE__),"..")
    Dir.chdir root
    set :config, File.join(root,'config')
    
    s.parse_config(YAML::load(open(File.join(config,'settings.yaml'))))
    enable :sessions
    set :bind, '127.0.0.1'
  end

  helpers do
    def get_relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(File.expand_path(settings.root))).to_s
    end
  end

  get '/' do
    erb :index
  end

  get '/help' do
    erb :help
  end

  get '/theme.set' do
    if File.exists?(File.join(settings.themes,"#{params['theme']}.html"))
      response.set_cookie('theme',params['theme'])
    else
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

  get '/data.set' do
    if File.exists?(File.join(settings.data,"#{params['data']}.yml")) or params['data'] == 'demo'
      response.set_cookie('data',params['data'])
    else
      halt 404, "Not found"
    end
  end

  get '/data.json' do
    data = {}
    Dir.glob("#{settings.data}/*.yml").collect do |datum|
      data[File.basename(datum,".yml")] = Digest::MD5.hexdigest(open(datum).read)
    end
    data['demo'] = Digest::MD5.hexdigest(open(File.join(settings.config,"demo.yml")).read)
    data.to_json
  end


  get %r{^/edit/(theme|data)$} do |file|
    halt 403, "Forbidden" if !settings.allowediting
  
    case file
    when 'theme'
      filename = "#{settings.themes}/#{request.cookies['theme']}.html"
    when 'data'
      filename = File.exists?(File.join(settings.data,"#{request.cookies['data']}.yml")) ? "#{settings.data}/#{request.cookies['data']}.yml" : File.join(settings.config,"demo.yml")
    else
      halt 400, "Not a valid edit selection"
    end
    if File.exists? filename
      # TODO: Send useful http status response
      puts "Launching #{settings.editor} to edit file #{filename}"
      `#{settings.editor} "#{filename}"`
    else
      puts "Failed to launch #{settings.editor} to edit file #{filename}"
      halt 404, "Odd, I can't find that file"
    end
  end
  
  get %r{/(tumblr)?settings.set} do |tumblr|
    halt 501 if tumblr == "tumblr" # TODO: Tumblr settings save
    
    settings.parse_config(params)
    open(File.join(settings.config,"settings.yaml"),"w") do |f|
      f.write YAML.dump({
        "Tumblr"          => settings.tumblr,
        "ThemesLocation"  => get_relative(settings.themes),
        "DataLocation"    => get_relative(settings.data),
        "AllowEditing"    => settings.allowediting,
        "Editor"          => settings.editor,
        "Port"            => settings.port
      })
    end
    
    "Settings saved"
  end

  # TODO: Downloads feed data from a tumblr site
  get '/import' do
    halt 501, "Sorry, I haven't written this bit yet!"
  end

  before do
    request.cookies['data'] ||= "demo"
    if request.env['REQUEST_PATH'] =~ /^\/thimblr/
      if File.exists?(File.join(settings.themes,"#{request.cookies['theme']}.html"))
        data = File.exists?(File.join(settings.data,"#{request.cookies['data']}.yml")) ? "#{settings.data}/#{request.cookies['data']}.yml" : File.join(settings.config,"demo.yml")
        @parser = Thimblr::Parser.new(data,"#{settings.themes}/#{request.cookies['theme']}.html",settings.tumblr)
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
  
  # TODO: Search page
  get %r{^/thimblr/search/(.+)$} do |query|
    @parser.render_search(query)
  end

  # TODO: tagged pages
  get %r{^/thimblr/tagged/(.+)$} do |tags|
    halt 501, "Not Implemented"
  end

  # Protected page names that shouldn't go to pages and aren't implemented in Thimblr
  get %r{^/thimblr/(?:rss|archive)$} do 
    halt 501, "Not Implemented"
  end

  # TODO: Pages
  get '/thimblr/*' do
    @parser.render_page(params[:splat])
  end
  
  # TODO: Only if Sinatra runs successfully
  Launchy.open("http://localhost:#{port}")
end