require "s3db/encryption_key"

module S3db
  class Fetcher

    def fetch
      aws, s3 = configure()
      bucket = choose_bucket(aws)
      last_dump_key = find_latest_dump(bucket, s3)
      latest_dump_path, latest_enc_dump_path = retrieve_latest_dump(bucket, last_dump_key, s3)
      decrypt(latest_dump_path, latest_enc_dump_path)
      decompress(latest_dump_path)
    end

    private

    def choose_bucket(aws)
      ENV['S3DB_BUCKET'] || aws['production']['bucket']
    end

    def configure
      aws = YAML::load_file(File.join(Rails.root, "config", "s3_config.yml"))
      s3 = RightAws::S3Interface.new(aws['aws_access_key_id'], aws['secret_access_key'])
      return aws, s3
    end

    def find_latest_dump(bucket, s3)
      all_dump_keys = s3.list_bucket(bucket, {:prefix => "mysql"})
      #@TODO deal with empty list
      all_dump_keys.sort { |a, b| a[:last_modified]<=>b[:last_modified] }.last
    end

    def retrieve_latest_dump(bucket, last_dump_key, s3)
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