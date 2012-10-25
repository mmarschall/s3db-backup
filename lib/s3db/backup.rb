require "s3db/configuration"

module S3db
  class Backup

    attr_accessor :config

    def configure
      S3db::Configuration.new
    end

    def initialize
      @config = configure()
    end

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
      mysql_dump_file_name = "mysql-#{config.db['database']}-#{Time.now.strftime('%Y-%m-%d-%Hh%Mm%Ss')}.sql.gz.cpt"
      s3 = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
      s3.put("#{config.aws['bucket']}", "#{mysql_dump_file_name}", encrypted_file.open)
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
      mysqldump = `which mysqldump`.strip
      raise "Please make sure that 'mysqldump' is installed and in your path!" if mysqldump.empty?
      "#{mysqldump} --user=#{config.db['username']} --password=#{config.db['password']} #{config.db['host'] ? "-h #{config.db['host']} " : ''}#{config.db['database']}"
    end

    def secret_encryption_key_path
      secret_key_path = ENV['S3DB_SECRET_KEY_PATH'] || File.join(Rails.root, "db", "secret.txt")
      raise "Please make sure you put your secret encryption key into: '#{secret_key_path}'" unless File.exists?(secret_key_path)
      secret_key_path
    end


  end
end