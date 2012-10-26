require "s3db/encryption_key"

module S3db
  class Commandline

    attr_reader :config, :tempfile

    def initialize(config, tempfile)
      @config = config
      @tempfile = tempfile
    end

    def dump_command
      command_chain = []
      command_chain << mysqldump_command()
      command_chain << gzip_command()
      command_chain << ccrypt_command()
      command_chain.join(" | ")
    end

    private

    def ccrypt_command
      ccrypt = locate_command_path('ccrypt')
      "#{ccrypt} -k #{S3db::EncryptionKey.path} -e > #{tempfile.path}"
    end

    def gzip_command
      gzip = locate_command_path('gzip')
      "#{gzip} -9"
    end

    def mysqldump_command()
      mysqldump = locate_command_path('mysqldump')
      command_chain = []
      command_chain << mysqldump
      command_chain << "--user=#{config.db['username']}"
      command_chain << "--password=#{config.db['password']}"
      command_chain << "--host #{config.db['host']}" if config.db['host']
      command_chain << "#{config.db['database']}"
      command_chain.join(" ")
    end

    def locate_command_path(command)
      command_full_path = `which #{command}`.strip
      raise "Please make sure that '#{command}' is installed and in your path!" if command_full_path.empty?
      command_full_path
    end
  end
end