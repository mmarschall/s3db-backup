require "s3db/configuration"

module S3db
  class Backup

    def backup
      encrypted_file = dump_database()
      upload_encrypted_database_dump(encrypted_file)
    end

    def dump_database
      encrypted_file = Tempfile.new("ccrypt_tempfile")
      system(command(encrypted_file))
      encrypted_file
    end

    def upload_encrypted_database_dump(encrypted_file)
      aws = configure_aws()
      config = configure_rails()
      mysql_dump_file_name = "mysql-#{config['database']}-#{Time.now.strftime('%Y-%m-%d-%Hh%Mm%Ss')}.sql.gz.cpt"
      s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
      s3.put("#{aws[::Rails.env]['bucket']}", "#{mysql_dump_file_name}", encrypted_file.open)
    end

    def configure_rails
      ActiveRecord::Base.configurations[::Rails.env]
    end

    def configure_aws
      aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
      ensure_bucket_name_found(aws)
      aws
    end

    def ensure_bucket_name_found(aws)
      raise "Please specify a bucket for your #{::Rails.env} environment in config/s3config.yml" if aws[::Rails.env].nil?
    end

    def command(encrypted_file)
      command_chain = []
      command_chain << mysqldump_command()
      command_chain << gzip_command()
      command_chain << ccrypt_command(encrypted_file)
      command_chain.join(" | ")
    end

    def ccrypt_command(encrypted_file)
      ccrypt = `which ccrypt`.strip
      raise "Please make sure that 'ccrypt' is installed and in your path!" if ccrypt.empty?
      "#{ccrypt} -k #{secret_encryption_key_path} -e > #{encrypted_file.path}"
    end

    def gzip_command
      gzip = `which gzip`.strip
      raise "Please make sure that 'gzip' is installed and in your path!" if gzip.empty?
      "#{gzip} -9"
    end

    def mysqldump_command()
      config = configure_rails()
      mysqldump = `which mysqldump`.strip
      raise "Please make sure that 'mysqldump' is installed and in your path!" if mysqldump.empty?
      "#{mysqldump} --user=#{config['username']} --password=#{config['password']} #{config['host'] ? "-h #{config['host']} " : ''}#{config['database']}"
    end

    def secret_encryption_key_path
      secret_key_path = ENV['S3DB_SECRET_KEY_PATH'] || File.join(Rails.root, "db", "secret.txt")
      raise "Please make sure you put your secret encryption key into: '#{secret_key_path}'" unless File.exists?(secret_key_path)
      secret_key_path
    end
  end
end