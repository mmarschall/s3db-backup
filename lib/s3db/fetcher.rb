require "s3db/encryption_key"

module S3db
  class Fetcher

    attr_reader :config
    attr_reader :latest_dump_path
    attr_accessor :storage

    def initialize
      @config = configure
      @latest_dump_path = "#{@config.latest_dump_path}.gz"
      @storage = S3db::Storage.new
    end

    def fetch
      storage.connect
      retrieve_latest_dump
      decrypt
      decompress
    end

    private

    def configure
      S3db::Configuration.new
    end

    def choose_bucket
      ENV['S3DB_BUCKET'] || config.aws['production']['bucket']
    end

    def find_latest_dump(bucket)
      files = storage.list_files(bucket, {:prefix => "mysql"})
      raise "No file with prefix 'mysql' found in bucket '#{bucket}'" if files.nil?
      files.sort { |a, b| a[:last_modified]<=>b[:last_modified] }.last
    end

    def retrieve_latest_dump
      bucket = choose_bucket
      latest_dump = find_latest_dump(bucket)
      puts "** Getting #{latest_dump[:key]} from #{bucket}"
      File.open("#{latest_dump_path}.cpt", "w+b") do |f|
        storage.retrieve_object(bucket, latest_dump[:key]) do |chunk|
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
