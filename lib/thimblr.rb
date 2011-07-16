require 'rubygems'
require 'sinatra'
require 'json'
require 'digest/md5'
require 'pathname'
require 'launchy'
require 'thimblr/parser'
require 'thimblr/importer'
require 'rbconfig'
require 'fileutils'

class Thimblr::Application < Sinatra::Base
  Editors = {
    'textmate' => {'command' => "mate",'platform' => "mac",'name' => "TextMate"},
    'bbedit'   => {'command' => "bbedit",'platform' => 'mac','name' => "BBEdit"},
    'textedit' => {'command' => "open -a TextEdit.app",'platform' => 'mac','name' => "TextEdit"}
  }
  Locations = {
    "mac" => {"dir" => "~/Library/Application Support/Thimblr/", 'name' => "Application Support", 'platform' => "mac"},
    "nix" => {'dir' => "~/.thimblr/",'name' => "Home directory", 'platform' => "nix"},
    "win" => {'dir' => "~/AppData/Roaming/Thimblr/",'name' => "AppData", 'platform' => "win"} # TODO: This value is hardcoded for vista/7, I should probably superceed expand_path and parse for different versions of Windows here
  }
  
  case RbConfig::CONFIG['target_os']
  when /darwin/i
    Platform = "mac"
  when /mswin32/i,/mingw32/i
    Platform = "win"
  else
    Platform = "nix"
  end
  
  def self.parse_config(s)
    set :themes, File.expand_path(File.join(Locations[Platform]['dir'],"themes"))
    set :data, File.expand_path(File.join(Locations[Platform]['dir'],"data"))
    set :allowediting, (s['AllowEditing']) ? true : false
    set :editor, s['Editor'] if s['Editor']
    set :tumblr, Thimblr::Parser::Defaults.merge(s['Tumblr'] || {})
    set :port, (s['Port'].to_i > 0) ? s['Port'].to_i  : 4567
  end
  
  configure do |s|
    set :root, File.join(File.dirname(__FILE__),"..")
    Dir.chdir root
    set :config, File.join(root,'config')
    set :settingsfile, File.expand_path(File.join(Locations[Platform]['dir'],'settings.yaml'))
    
    # Generate Data & Theme directories if required
      FileUtils.cp_r(File.join(root,'themes'),File.expand_path(Locations[Platform]['dir'])) if not File.directory?(File.expand_path(File.join(Locations[Platform]['dir'],"themes")))
    
    if not File.directory?(File.expand_path(File.join(Locations[Platform]['dir'],"data")))
      FileUtils.mkdir_p(File.expand_path(File.join(Locations[Platform]['dir'],"data")))
      FileUtils.cp(File.join(config,'demo.yml'),File.expand_path(File.join(Locations[Platform]['dir'],'data','demo.yml')))
    end
    
    begin # Try to load the settings file, if it's crap then overwrite it with the defaults
      s.parse_config(YAML::load(open(settingsfile)))
    rescue
      FileUtils.cp(File.join(config,'settings.default.yaml'),settingsfile)
      retry
    end
    
    enable :sessions
    set :bind, '127.0.0.1'
    
    # Dirty hack cos Windows support in Launchy appears to be broken
    if Platform == 'win'
      `start http://localhost:#{port}`
    else
      Launchy.open("http://localhost:#{port}")
    end
  end

  helpers do
    def get_relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(File.expand_path(settings.root))).to_s
    end
  end

  get '/' do
    redirect 'index.html'
  end

  get '/menu' do
    erb :menu
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
    if File.exists?(File.join(settings.data,"#{params['data']}.yml"))
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
    
    params['AllowEditing'] = (params['AllowEditing'] == "on")
    settings.parse_config(params)
    open(settings.settingsfile,"w") do |f|
      f.write YAML.dump({
        "Tumblr"          => settings.tumblr,
        "AllowEditing"    => settings.allowediting,
        "Editor"          => settings.editor,
        "Port"            => settings.port
      })
    end
    
    "Settings saved"
  end

  # Downloads feed data from a tumblr site
  get %r{/import/([a-zA-Z0-9-]+)} do |username|
    begin
      data = Thimblr::Import.username(username)
      open(File.join(settings.data,"#{username}.yml"),'w') do |f|
        f.write data
      end
    rescue Exception => e
      halt 404, e.message
    end
    "Imported as '#{username}'"
  end

  before do
    request.cookies['data'] ||= "demo"
    if request.env['PATH_INFO'] =~ /^\/thimblr/
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
end