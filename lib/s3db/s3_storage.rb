module S3db
  class S3Storage

    attr_reader :config, :connection

    def initialize(config)
      @config = config
      @connection = open_s3_connection
    end

    def retrieve_object(bucket, key)
      connection.retrieve_object(:bucket => bucket, :key => key)
    end

    def list_files(bucket, prefix = "")
      connection.list_files(bucket, {:prefix => prefix})
    end

    def put(bucket, file_name, source_file)
      connection.put(bucket, "#{file_name}", source_file.open)
    end

    private

    def open_s3_connection
      RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
    end
  end
end