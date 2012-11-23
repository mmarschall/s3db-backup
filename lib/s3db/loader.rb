module S3db
  class Loader

    attr_reader :config

    def initialize
      @config = configure
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
      drop_database
      create_database
    end

    def drop_database
      ActiveRecord::Base.establish_connection(config.db)
      puts "** dropping database #{config.db['database']}"
      ActiveRecord::Base.connection.drop_database(config.db['database']) rescue nil
    end

    def create_database
      puts "** creating database #{config.db['database']}"
      ActiveRecord::Base.establish_connection(config.db.merge('database' => nil))
      ActiveRecord::Base.connection.create_database(config.db['database'], config.db)
      ActiveRecord::Base.establish_connection(config.db)
    end

    def load_dump
      puts "** Loading dump with mysql into #{config.db['database']}"
      cmd = command_line.load_command(config.latest_dump_path)
      result = system(cmd)
      raise "Loading dump with mysql into #{config.db['database']} failed with exit code: #{$?}" unless result
    end
  end
end