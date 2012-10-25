require "s3db/configuration"

module S3db
  class Backup

    attr_reader :config, :encrypted_file

    def initialize
      @config = configure()
      @encrypted_file = Tempfile.new("s3db_backup_tempfile")
    end

    def backup
      dump_database()
      upload_encrypted_database_dump()
    end

    private

    def configure
      S3db::Configuration.new
    end

    def dump_database
      system(dump_command)
    end

    def upload_encrypted_database_dump
      mysql_dump_file_name = "mysql-#{config.db['database']}-#{Time.now.strftime('%Y-%m-%d-%Hh%Mm%Ss')}.sql.gz.cpt"
      s3 = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
      s3.put("#{config.aws['bucket']}", "#{mysql_dump_file_name}", encrypted_file.open)
    end


    def dump_command
      command_chain = []
      command_chain << mysqldump_command()
      command_chain << gzip_command()
      command_chain << ccrypt_command()
      command_chain.join(" | ")
    end

    def ccrypt_command
      ccrypt = locate_command_path('ccrypt')
      "#{ccrypt} -k #{secret_encryption_key_path} -e > #{encrypted_file.path}"
    end

    def gzip_command
      gzip = locate_command_path('gzip')
      "#{gzip} -9"
    end

    def mysqldump_command()
      mysqldump = locate_command_path('mysqldump')
      "#{mysqldump} --user=#{config.db['username']} --password=#{config.db['password']} #{config.db['host'] ? "-h #{config.db['host']} " : ''}#{config.db['database']}"
    end

    def locate_command_path(command)
      command_full_path = `which #{command}`.strip
      raise "Please make sure that '#{command}' is installed and in your path!" if command_full_path.empty?
      command_full_path
    end

    def secret_encryption_key_path
      secret_key_path = ENV['S3DB_SECRET_KEY_PATH'] || File.join(Rails.root, "db", "secret.txt")
      raise "Please make sure you put your secret encryption key into: '#{secret_key_path}'" unless File.exists?(secret_key_path)
      secret_key_path
    end


  end
end