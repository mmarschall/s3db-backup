module S3db
  class Storage

    attr_reader :config
    attr_reader :connection

    def initialize
      @config = configure
    end

    def list_files(bucket, options = {})
      connection.list_bucket(bucket, options)
    end

    def retrieve_object(bucket, key, &block)
      connection.retrieve_object(:bucket => bucket, :key => key) do |chunk|
        yield(chunk)
      end
    end

    def put_object(bucket, key, object)
      connection.put(bucket, key, object)
      key
    end

    def connect
      @connection = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
    end

    private

    def configure
      S3db::Configuration.new
    end

  end
end
