require "s3db/encryption_key"

module S3db
  class Fetcher

    attr_reader :config, :s3
    attr_reader :latest_dump_path

    def initialize
      @config = configure
      @latest_dump_path = "#{@config.latest_dump_path}.gz"
    end

    def fetch
      open_s3_connection
      retrieve_latest_dump
      decrypt
      decompress
    end

    private

    def configure
      S3db::Configuration.new
    end

    def open_s3_connection
      @s3 = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
    end

    def choose_bucket
      ENV['S3DB_BUCKET'] || config.aws['production']['bucket']
    end

    def find_latest_dump(bucket)
      all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
      raise "No file with prefix 'mysql' found in bucket '#{bucket}'" if all_dump_keys.nil?
      all_dump_keys.sort { |a, b| a[:last_modified]<=>b[:last_modified] }.last
    end

    def retrieve_latest_dump
      bucket = choose_bucket
      last_dump_key = find_latest_dump(bucket)
      puts "** Getting #{last_dump_key[:key]} from #{bucket}"
      File.open("#{latest_dump_path}.cpt", "w+b") do |f|
        s3.retrieve_object(:bucket => bucket, :key => last_dump_key[:key]) do |chunk|
          f.write(chunk)
        end
      end
    end

    def decrypt
      puts "** decrypting dump"
      system("rm -f #{latest_dump_path} && ccrypt -k #{S3db::EncryptionKey.path} -d #{latest_dump_path}.cpt")
    end

    def decompress
      raise "#{latest_dump_path} not found" unless File.exists?(latest_dump_path)
      puts "** Gunzipping #{latest_dump_path}"
      result = system("cd db && gunzip -f #{latest_dump_path}")
      raise "Gunzipping '#{latest_dump_path}' failed with exit code: #{result}" unless result
    end
  end
end