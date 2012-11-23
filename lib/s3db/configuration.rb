module S3db
  class Configuration

    attr_reader :db
    attr_reader :aws
    attr_reader :latest_dump_path

    def initialize
      @db = configure_db
      @aws = configure_aws
      @latest_dump_path = File.join(::Rails.root, 'db', "latest_dump.sql")
    end

    private

    def configure_db
      database_config = ENV['S3DB_DATABASE_CONFIG'] || ::Rails.env
      ActiveRecord::Base.configurations[database_config]
    end

    def configure_aws
      aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
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
      super("Please specify your #{key} in config/s3config.yml")
    end
  end
end