require "right_aws"
require "yaml"
require "progressbar"

class S3dbBackup
  def self.backup
    aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
    config = ActiveRecord::Base.configurations[RAILS_ENV]

    mysqldump = `which mysqldump`.strip
    raise "Please make sure that 'mysqldump' is installed and in your path!" if mysqldump.empty?
    
    gzip = `which gzip`.strip
    raise "Please make sure that 'gzip' is installed and in your path!" if gzip.empty?

    ccrypt = `which ccrypt`.strip
    raise "Please make sure that 'ccrypt' is installed and in your path!" if ccrypt.empty?
    
    raise "Please specify a bucket for your #{RAILS_ENV} environment in config/s3config.yml" if aws[RAILS_ENV].nil?

    latest_dump = "mysql-#{config['database']}-#{Time.now.strftime('%d-%m-%Y-%Hh%Mm%Ss')}.sql.gz"
    mysql_dump_path = Tempfile.new(latest_dump).path


    system("#{mysqldump} --user=#{config['username']} --password=#{config['password']} #{config['host'] ? "-h #{config['host']}" : ''} #{config['database']} | #{gzip} -9 > #{mysql_dump_path}")

    encrypted_file_path = Tempfile.new("ccrypt_tempfile").path
    ccrypt_command = "cat #{mysql_dump_path} | #{ccrypt} -k #{File.join(Rails.root, "db", "secret.txt")} -e > #{encrypted_file_path}"
    `#{ccrypt_command}`


    s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
    s3.put("#{aws[RAILS_ENV]['bucket']}", "#{latest_dump}.cpt", File.open(encrypted_file_path))
  end
  
  def self.fetch
    aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
    s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
    bucket = aws['production']['bucket']
    all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
    last_dump_key = all_dump_keys.sort{|a,b| a[:last_modified]<=>b[:last_modified]}.last
    content_length = last_dump_key[:size]
    puts "** Getting #{last_dump_key[:key]} from #{bucket}"
    progress = ProgressBar.new("** s3 get", content_length)

    latest_dump_path = File.join(Rails.root, "db", "latest_prod_dump.sql.gz")
    latest_enc_dump_path = "#{latest_dump_path}.cpt"
    File.open(latest_enc_dump_path, "w+") do |f|
      s3.retrieve_object(:bucket => bucket, :key => last_dump_key[:key]) do |chunk|
        progress.inc(chunk.length)
        f.write(chunk)
      end
    end
    progress.finish

    puts "** decrypting dump"
    `rm -f #{latest_dump_path} && ccrypt -k #{File.join(Rails.root, "db", "secret.txt")} -d #{latest_enc_dump_path}`
  end
  
  def self.load
    config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
    ActiveRecord::Base.connection.recreate_database(config['database'], config)
    puts "** Untarring db/latest_prod_dump.sql.gz"
    system("cd db && gunzip latest_prod_dump.sql.gz") if File.exist?("db/latest_prod_dump.sql.gz")

    puts "** Loading dump with mysql into #{config['database']}"

    system("$(which mysql) --user #{config['username']} #{"--password=#{config['password']}" unless config['password'].blank?} --database #{config['database']} < db/latest_prod_dump.sql")

    connection_pool = ActiveRecord::Base.establish_connection(RAILS_ENV || 'development')
    anonymize_dump(config, connection_pool.connection)

    puts "** Successfully loaded and anonymized latest dump into #{config['database']}"
  end
  
  def self.anonymize
    puts "** Anonymizing all email columns in the database"
    config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
    connection_pool = ActiveRecord::Base.establish_connection(RAILS_ENV || 'development')
    anonymize_dump(config, connection_pool.connection)
  end  
  
  def self.anonymize_dump(config, connection)
  end
  
  def self.sync_shared_system_files
    aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
    system("bash -c 'AWS_ACCESS_KEY_ID=#{aws['aws_access_key_id']} AWS_SECRET_ACCESS_KEY=#{aws['secret_access_key']} AWS_CALLING_FORMAT=SUBDOMAIN $(which s3sync) -s -r #{RAILS_ROOT}/shared/system #{aws[RAILS_ENV || 'development']['bucket']}:files'")
  end
end