require "s3db/configuration"
require "s3db/command_line"
require "s3db/s3_storage"

module S3db
  class Backup

    attr_reader :config, :storage, :encrypted_file

    def initialize
      @config = configure
      @encrypted_file = Tempfile.new("s3db_backup_tempfile")
      @storage = storage_connection
    end

    def backup
      dump_database
      upload_encrypted_database_dump
    end

    private

    def configure
      S3db::Configuration.new
    end

    def storage_connection
      S3Storage.new(config)
    end

    def dump_database
      command_line = CommandLine.new(config)
      system(command_line.dump_command(encrypted_file))
    end

    def upload_encrypted_database_dump
      mysql_dump_file_name = "mysql-#{config.db['database']}-#{Time.now.strftime('%Y-%m-%d-%Hh%Mm%Ss')}.sql.gz.cpt"
      storage.put("#{config.aws['bucket']}", "#{mysql_dump_file_name}", encrypted_file)
    end
  end
end