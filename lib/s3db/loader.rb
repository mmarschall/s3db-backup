module S3db
  class Loader

    attr_reader :config
    attr_reader :latest_dump_path
    
    def initialize
      @config = configure
      @latest_dump_path = @config.latest_dump_path
    end
    
    def configure
      S3db::Configuration.new
    end

    def command_line
      CommandLine.new(config)
    end

    def load
      recreate_database
      load_dump
      anonymize_database
      puts "** Successfully loaded and anonymized latest dump into #{config.db['database']}"
    end

    def anonymize_database
      puts "** Anonymizing database"
      connection_pool = ActiveRecord::Base.establish_connection(config.db)
      S3dbBackup.anonymize_dump(config.db, connection_pool.connection) unless ::Rails.env == 'production'
    end

    private

    def recreate_database
      puts "** using database configuration for environment: '#{::Rails.env}'"
      ActiveRecord::Base.establish_connection(config.db)
      puts "** dropping database #{config.db['database']}"
      ActiveRecord::Base.connection.drop_database(config.db['database']) rescue nil
      puts "** creating database #{config.db['database']}"
      ActiveRecord::Base.establish_connection(config.db.merge('database' => nil))
      ActiveRecord::Base.connection.create_database(config.db['database'], config.db)
      ActiveRecord::Base.establish_connection(config.db)
    end

    def load_dump
      puts "** Loading dump with mysql into #{config.db['database']}"
      cmd = command_line.load_command(latest_dump_path)
      result = system(cmd)
      raise "Loading dump with mysql into #{config.db['database']} failed with exit code: #{$?}" unless result
    end
  end
end