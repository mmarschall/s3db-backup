module S3db
  class Loader

    attr_reader :config
    attr_reader :latest_dump_path
    
    def initialize
      @config = configure
      #@TODO this needs to be DRYed (see S3db::Fetcher#initialize)
      @latest_dump_path = File.join(Rails.root, "db", "latest_prod_dump.sql")
    end
    
    def configure
      S3db::Configuration.new
    end

    def load
      recreate_database
      load_dump
      anonymize_database
      puts "** Successfully loaded and anonymized latest dump into #{config.db['database']}"
    end

    def anonymize_database
      puts "** Anonymizing database"
      connection_pool = ActiveRecord::Base.establish_connection(::Rails.env)
      S3dbBackup.anonymize_dump(config.db, connection_pool.connection) unless ::Rails.env == 'production'
    end

    private

    def recreate_database
      puts "** using database configuration for environment: '#{::Rails.env}'"
      puts "** re-creating database #{config.db['database']}"
      #@TODO create db if not yet existing (for bootstrapping an app from the db backup)
      ActiveRecord::Base.connection.recreate_database(config.db['database'], config.db)
    end

    def load_dump
      puts "** Loading dump with mysql into #{config.db['database']}"

      result = false
      #cmd = "$(which mysql) --user #{config.db['username']} #{"--password=#{config.db['password']}" unless config.db['password'].blank?} --database #{config.db['database']} #{"--host=#{config.db['host']}" unless config.db['host'].blank?} #{"--port=#{config.db['port']}" unless config.db['port'].blank?} < db/latest_prod_dump.sql"
      cmd = CommandLine.new(config).load_command(latest_dump_path)
      puts cmd
      result = system(cmd)
      raise "Loading dump with mysql into #{config.db['database']} failed with exit code: #{$?}" unless result
    end
  end
end