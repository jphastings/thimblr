require 'rubygems'
require 'rake'
require 'rake/gempackagetask'

name = "Thimblr"
version = File.exist?('VERSION') ? File.read('VERSION') : ""

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = name
    gem.version = version
    gem.summary = %Q{Helper for Tumblr theme editors}
    gem.description = %Q{A webserver built to help you test tumblr themes as you edit them}
    gem.email = "jphastings@gmail.com"
    gem.homepage = "http://github.com/jphastings/Thimblr"
    gem.author = "JP Hastings-Spital"
    gem.add_dependency "sinatra"
    gem.add_dependency "launchy"
    gem.files = FileList['lib/**/*','data/**/*','themes/**/*','config/**/*','views/**/*']
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

task :test => :check_dependencies

task :default => :install

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "#{name} #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end