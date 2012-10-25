require "right_aws"
require "yaml"
require "tempfile"
require "s3db/backup"

class S3dbBackup

  #@TODO not needed (I guess)
  class << self
    attr_accessor :rails_env
  end

  def self.backup_instance
    S3db::Backup.new
  end

  # this class method is needed for backward compatibility <= 0.6.4
  def self.backup
    backup_instance.backup
  end

  def self.fetch
    aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
    s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
    bucket = ENV['S3DB_BUCKET'] || aws['production']['bucket']
    all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
    last_dump_key = all_dump_keys.sort { |a, b| a[:last_modified]<=>b[:last_modified] }.last
    puts "** Getting #{last_dump_key[:key]} from #{bucket}"

    latest_dump_path = File.join(Rails.root, "db", "latest_prod_dump.sql.gz")
    latest_enc_dump_path = "#{latest_dump_path}.cpt"
    File.open(latest_enc_dump_path, "w+b") do |f|
      s3.retrieve_object(:bucket => bucket, :key => last_dump_key[:key]) do |chunk|
        f.write(chunk)
      end
    end

    puts "** decrypting dump"
    `rm -f #{latest_dump_path} && ccrypt -k #{secret_encryption_key_path} -d #{latest_enc_dump_path}`
  end

  def self.secret_encryption_key_path
    secret_key_path = ENV['S3DB_SECRET_KEY_PATH'] || File.join(Rails.root, "db", "secret.txt")
    raise "Please make sure you put your secret encryption key into: '#{secret_key_path}'" unless File.exists?(secret_key_path)
    secret_key_path
  end

  def self.load
    database_env = self.rails_env || ::Rails.env || "development"
    puts "** using database configuration for environment: '#{database_env}'"
    config = ActiveRecord::Base.configurations[database_env]
    puts "** re-creating database #{config['database']}"
    ActiveRecord::Base.connection.recreate_database(config['database'], config)
    puts "** Gunzipping db/latest_prod_dump.sql.gz"
    result = false
    result = system("cd db && gunzip -f latest_prod_dump.sql.gz") if File.exist?("db/latest_prod_dump.sql.gz")
    raise "Gunzipping db/latest_prod_dump.sql.gz failed with exit code: #{result}" unless result

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
