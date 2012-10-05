# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 's3db-backup'

Gem::Specification.new do |s|
  s.name        = "s3db-backup"
  s.version     = S3dbBackup::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Matthias Marschall"]
  s.email       = ["mm@agileweboperations.com"]
  s.homepage    = "http://rubygems.org/gems/s3db-backup"
  s.summary     = %q{Backup and restore the database of your rails app to amazon S3, encrypting and compressing it on the fly}
  s.description = %q{This gem helps you to easily create backups of the database of your rails app and store them on amazon S3. It uses standard Unix tools to do the heavy lifting like dumping the db (mysqldump), compressing (gzip, tar), and encrypting (ccrypt).}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'right_aws', '>= 2.0.0'
  s.add_development_dependency 'rspec', '>= 1.2.9'
  s.add_development_dependency 'rails', '~> 2.3'
end
