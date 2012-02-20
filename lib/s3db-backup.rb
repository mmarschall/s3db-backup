require "right_aws"
require "yaml"

class S3dbBackup

  class << self
    attr_accessor :rails_env
    attr_accessor :version
    @version = File.open(File.expand_path(File.dirname(__FILE__)) + "/../VERSION", "r").read
  end

  def self.backup
    aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
    config = ActiveRecord::Base.configurations[::Rails.env]

    mysqldump = `which mysqldump`.strip
    raise "Please make sure that 'mysqldump' is installed and in your path!" if mysqldump.empty?

    gzip = `which gzip`.strip
    raise "Please make sure that 'gzip' is installed and in your path!" if gzip.empty?

    ccrypt = `which ccrypt`.strip
    raise "Please make sure that 'ccrypt' is installed and in your path!" if ccrypt.empty?

    raise "Please specify a bucket for your #{::Rails.env} environment in config/s3config.yml" if aws[::Rails.env].nil?

    latest_dump = "mysql-#{config['database']}-#{Time.now.strftime('%d-%m-%Y-%Hh%Mm%Ss')}.sql.gz"
    mysql_dump_path = Tempfile.new(latest_dump).path


    system("#{mysqldump} --user=#{config['username']} --password=#{config['password']} #{config['host'] ? "-h #{config['host']}" : ''} #{config['database']} | #{gzip} -9 > #{mysql_dump_path}")

    encrypted_file_path = Tempfile.new("ccrypt_tempfile").path
    ccrypt_command = "cat #{mysql_dump_path} | #{ccrypt} -k #{File.join(Rails.root, "db", "secret.txt")} -e > #{encrypted_file_path}"
    `#{ccrypt_command}`


    s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
    s3.put("#{aws[::Rails.env]['bucket']}", "#{latest_dump}.cpt", File.open(encrypted_file_path))
  end

  def self.fetch
    aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
    s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
    bucket = ENV['S3DB_BUCKET'] || aws['production']['bucket']
    all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
    last_dump_key = all_dump_keys.sort{|a,b| a[:last_modified]<=>b[:last_modified]}.last
    puts "** Getting #{last_dump_key[:key]} from #{bucket}"

    latest_dump_path = File.join(Rails.root, "db", "latest_prod_dump.sql.gz")
    latest_enc_dump_path = "#{latest_dump_path}.cpt"
    File.open(latest_enc_dump_path, "w+") do |f|
      s3.retrieve_object(:bucket => bucket, :key => last_dump_key[:key]) do |chunk|
        f.write(chunk)
      end
    end

    puts "** decrypting dump"
    secret_key_path = ENV['S3DB_SECRET_KEY_PATH'] || File.join(Rails.root, "db", "secret.txt")
    `rm -f #{latest_dump_path} && ccrypt -k #{secret_key_path} -d #{latest_enc_dump_path}`
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
    anonymize_dump(config, connection_pool.connection)

    puts "** Successfully loaded and anonymized latest dump into #{config['database']}"
  end

  def self.anonymize
    puts "** Anonymizing all email columns in the database"
    config = ActiveRecord::Base.configurations[::Rails.env || 'development']
    connection_pool = ActiveRecord::Base.establish_connection(::Rails.env || 'development')
    anonymize_dump(config, connection_pool.connection)
  end

  def self.anonymize_dump(config, connection)
  end
end
