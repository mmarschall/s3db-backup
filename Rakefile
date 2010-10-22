require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "s3db-backup"
    gem.summary = %Q{Backup and restore your database to amazon S3, encrypting and compressing it on the way}
    gem.description = %Q{This gem helps you to easily create backups of your database and store them on amazon S3. It uses standard Unix tools to do the heavy lifting like dumping the db (mysqldump), compressing (gzip, tar), and encrypting (ccrypt).}
    gem.email = "mm@agileweboperations.com"
    gem.homepage = "http://github.com/mmarschall/s3db-backup"
    gem.authors = ["Matthias Marschall"]
    gem.add_dependency "right_aws", "~> 2.0.0"
    gem.add_dependency "progressbar", ">= 0.9.0"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "s3db-backup #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
