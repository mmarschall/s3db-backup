require "s3db/encryption_key"

module S3db
  class CommandLine

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def dump_command(tempfile)
      command_chain = []
      command_chain << mysqldump_command
      command_chain << gzip_command
      command_chain << ccrypt_command(tempfile)
      command_chain.join(" | ")
    end

    def load_command(latest_dump_path)
      command_chain = []
      command_chain << locate_command_path('mysql')
      command_chain << mysql_params
      command_chain << "--database=#{config.db['database']}"
      command_chain << "< #{latest_dump_path}"
      command_chain.join(" ")
    end

    private

    def ccrypt_command(tempfile)
      ccrypt = locate_command_path('ccrypt')
      "#{ccrypt} -k #{S3db::EncryptionKey.path} -e > #{tempfile.path}"
    end

    def gzip_command
      gzip = locate_command_path('gzip')
      "#{gzip} -9"
    end

    def mysqldump_command
      command_chain = []
      command_chain << locate_command_path('mysqldump')
      command_chain << mysql_params
      command_chain << "#{config.db['database']}"
      command_chain.join(" ")
    end

    def locate_command_path(command)
      command_full_path = find_executable(command)
      raise "Please make sure that '#{command}' is installed and in your path!" if command_full_path.empty?
      command_full_path
    end

    def find_executable(command)
      `which #{command}`.strip
    end

    def mysql_params
      command_chain = []
      command_chain << "--user=#{config.db['username']}"
      command_chain << "--password=#{config.db['password']}" if config.db['password']
      command_chain << "--host=#{config.db['host']}" if config.db['host']
      command_chain << "--port=#{config.db['port']}" if config.db['port']
      command_chain.join(" ")
    end
  end
end