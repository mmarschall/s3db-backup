require "s3db/encryption_key"

module S3db
  class Fetcher

    attr_reader :config, :s3

    def initialize
      @config = configure()
      @s3 = RightAws::S3Interface.new(config.aws['aws_access_key_id'], config.aws['secret_access_key'])
    end

    def fetch
      bucket = choose_bucket
      last_dump_key = find_latest_dump(bucket)
      latest_dump_path, latest_enc_dump_path = retrieve_latest_dump(bucket, last_dump_key)
      decrypt(latest_dump_path, latest_enc_dump_path)
      decompress(latest_dump_path)
    end

    private

    def configure
      S3db::Configuration.new
    end

    def choose_bucket
      ENV['S3DB_BUCKET'] || config.aws['production']['bucket']
    end

    def find_latest_dump(bucket)
      all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
      #@TODO deal with empty list
      all_dump_keys.sort { |a, b| a[:last_modified]<=>b[:last_modified] }.last
    end

    def retrieve_latest_dump(bucket, last_dump_key)
      puts "** Getting #{last_dump_key[:key]} from #{bucket}"
      latest_dump_path = File.join(Rails.root, "db", "latest_prod_dump.sql.gz")
      latest_enc_dump_path = "#{latest_dump_path}.cpt"
      File.open(latest_enc_dump_path, "w+b") do |f|
        s3.retrieve_object(:bucket => bucket, :key => last_dump_key[:key]) do |chunk|
          f.write(chunk)
        end
      end
      return latest_dump_path, latest_enc_dump_path
    end

    def decrypt(latest_dump_path, latest_enc_dump_path)
      puts "** decrypting dump"
      `rm -f #{latest_dump_path} && ccrypt -k #{S3db::EncryptionKey.path} -d #{latest_enc_dump_path}`
    end

    def decompress(latest_dump_path)
      puts "** Gunzipping #{latest_dump_path}"
      result = false
      result = system("cd db && gunzip -f #{latest_dump_path}") if File.exist?(latest_dump_path)
      raise "Gunzipping '#{latest_dump_path}' failed with exit code: #{result}" unless result
    end
  end
end