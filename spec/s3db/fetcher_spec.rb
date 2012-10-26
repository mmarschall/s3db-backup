require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Fetcher do

  let(:fetcher) { S3db::Fetcher.new }
  let!(:aws) { stub_right_aws() }

  before do
    stub_configuration

    File.stub(:open)
    File.stub(:exists?).with('./db/latest_prod_dump.sql.gz').and_return(true)

    fetcher.stub(:system => 0)
    fetcher.stub(:puts)
  end

  describe "attributes" do
    it "has reader for config" do
      fetcher.config.should be_a(S3db::Configuration)
    end
    it "has reader for latest_dump_path" do
      fetcher.latest_dump_path.should == './db/latest_prod_dump.sql.gz'
    end
  end

  describe "initialize" do
    it "instantiates a configuration instance" do
      S3db::Configuration.should_receive(:new)
      S3db::Fetcher.new
    end
  end

  describe "fetch" do

    describe "at least one file with prefix 'mysql' are found" do
      it "uses the latest one"
      it "downloads the latest dump"
      it "writes the downloaded dump to a file"

      it "decrypts the latest dump" do
        fetcher.should_receive(:system).with("rm -f ./db/latest_prod_dump.sql.gz && ccrypt -k ./db/secret.txt -d ./db/latest_prod_dump.sql.gz.cpt")
        fetcher.fetch
      end

      it "decompresses the latest dump" do
        fetcher.should_receive(:system).with("cd db && gunzip -f ./db/latest_prod_dump.sql.gz")
        fetcher.fetch
      end

      describe "decompression fails" do
        it "raises an error" do
          fetcher.stub(:system => false)
          expect { fetcher.fetch }.to raise_error("Gunzipping './db/latest_prod_dump.sql.gz' failed with exit code: false")
        end
      end

      describe "downloaded file not existing when trying to decompress" do
        it "raises an error" do
          File.stub(:exists?).with('./db/latest_prod_dump.sql.gz').and_return(false)
          expect { fetcher.fetch }.to raise_error("./db/latest_prod_dump.sql.gz not found")
        end
      end
    end

    describe "no latest dump with prefix 'mysql' found" do
      it "raises an error" do
        aws.stub(:list_bucket).and_return(nil)
        expect { fetcher.fetch }.to raise_error("No file with prefix 'mysql' found in bucket 's3db_backup_production_bucket'")
      end
    end

    describe "S3DB_BUCKET not set" do
      it "uses the production bucket by default" do
        aws.should_receive(:list_bucket).with("s3db_backup_production_bucket", {:prefix => "mysql"})
        fetcher.fetch
      end
    end

    describe "S3DB_BUCKET env set" do
      it "uses the env variable value as bucket name" do
        ENV['S3DB_BUCKET'] = "a-bucket"
        aws.should_receive(:list_bucket).with("a-bucket", {:prefix => "mysql"})
        fetcher.fetch
        ENV['S3DB_BUCKET'] = nil
      end
    end
  end
end