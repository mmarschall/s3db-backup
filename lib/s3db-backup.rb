require "right_aws"
require "yaml"
require "tempfile"
require "s3db/backup"
require "s3db/fetcher"

class S3dbBackup

  #@TODO not needed (I guess)
  class << self
    attr_accessor :rails_env
  end

  def self.backup_instance
    S3db::Backup.new
  end

  def self.fetcher
    S3db::Fetcher.new
  end

  # this class method is needed for backward compatibility <= 0.6.4
  def self.backup
    backup_instance.backup
  end

  def self.fetch
    fetcher.fetch
  end


  def self.load
    database_env = self.rails_env || ::Rails.env || "development"
    puts "** using database configuration for environment: '#{database_env}'"
    config = ActiveRecord::Base.configurations[database_env]
    puts "** re-creating database #{config['database']}"
    #@TODO create db if not yet existing (for bootstrapping an app from the db backup)
    ActiveRecord::Base.connection.recreate_database(config['database'], config)

    puts "** Loading dump with mysql into #{config['database']}"

    result = false
    cmd = "$(which mysql) --user #{config['username']} #{"--password=#{config['password']}" unless config['password'].blank?} --database #{config['database']} #{"--host=#{config['host']}" unless config['host'].blank?} #{"--port=#{config['port']}" unless config['port'].blank?} < db/latest_prod_dump.sql"
    result = system(cmd)
    raise "Loading dump with mysql into #{config['database']} failed with exit code: #{$?}" unless result

    connection_pool = ActiveRecord::Base.establish_connection(database_env)
    anonymize_dump(config, connection_pool.connection) unless ::Rails.env == 'production'

    puts "** Successfully loaded and anonymized latest dump into #{config['database']}"
  end

  def self.anonymize
    puts "** Anonymizing database"
    config = ActiveRecord::Base.configurations[::Rails.env || 'development']
    connection_pool = ActiveRecord::Base.establish_connection(::Rails.env || 'development')
    anonymize_dump(config, connection_pool.connection)
  end

  def self.anonymize_dump(config, connection)
  end
end
