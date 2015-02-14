module S3db
  class Configuration

    attr_reader :db
    attr_reader :aws
    attr_reader :compression
    attr_reader :mysql_options
    attr_reader :latest_dump_path

    def initialize
      @db = configure_db
      @aws = configure_aws
      @compression = @aws.fetch('compression', '9')
      @mysql_options = @aws.fetch('mysql_options', [])
      @latest_dump_path = File.join(::Rails.root, 'db', "latest_dump.sql")
    end

    private

    def configure_db
      database_config = ENV['S3DB_DATABASE_CONFIG'] || ::Rails.env
      ActiveRecord::Base.configurations[database_config]
    end

    def configure_aws
      template = ERB.new File.new(File.join(Rails.root, "config", "s3_config.yml")).read
      aws = YAML.load template.result(binding)
      
      validate_presence_of(aws, 'aws_access_key_id')
      validate_presence_of(aws, 'secret_access_key')
      validate_presence_of(aws, ::Rails.env)

      set_bucket_for_rails_env(aws)

      aws
    end

    def set_bucket_for_rails_env(aws)
      env_config = aws[::Rails.env]
      validate_presence_of(env_config, 'bucket')
      aws['bucket'] = env_config['bucket']
    end

    def validate_presence_of(hash, key)
      hash.fetch(key) { raise S3db::AwsConfigurationError.new(key) }
    end
  end

  class AwsConfigurationError < StandardError
    def initialize(key)
      super("Please specify your #{key} in config/s3_config.yml")
    end
  end
end
