require "s3db/configuration"
require "s3db/command_line"

module S3db
  class Backup

    attr_reader :config, :encrypted_file

    def initialize
      @config = configure()
      @encrypted_file = Tempfile.new("s3db_backup_tempfile")
    end

    def backup
      dump_database
      upload_encrypted_database_dump
    end

    private

    def configure
      S3db::Configuration.new
    end

    def dump_database
      command_line = CommandLine.new(config, encrypted_file)
      system(command_line.dump_command)
    end

    def upload_encrypted_database_dump
      mysql_dump_file_name = "mysql-#{config.db['database']}-#{Time.now.strftime('%Y-%m-%d-%Hh%Mm%Ss')}.sql.gz.cpt"
      s3 = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
      s3.put("#{config.aws['bucket']}", "#{mysql_dump_file_name}", encrypted_file.open)
    end
  end
end