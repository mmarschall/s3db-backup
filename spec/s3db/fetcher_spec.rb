require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))


def stub_file_open
  file = double("a file")
  file.stub(:write)
  File.stub(:open).and_yield(file)
end

describe S3db::Fetcher do

  let(:fetcher) { S3db::Fetcher.new }

  before do
    stub_configuration

    fetcher.storage = stub_storage

    File.stub(:open)
    File.stub(:exists?).with('./db/latest_dump.sql.gz').and_return(true)

    fetcher.stub(:system => 0)
    fetcher.stub(:puts)
  end


  describe "attributes" do
    it "has reader for config" do
      fetcher.config.should be_a(S3db::Configuration)
    end
    it "has reader for latest_dump_path" do
      fetcher.latest_dump_path.should == './db/latest_dump.sql.gz'
    end
  end

  describe "initialize" do
    it "instantiates a configuration instance" do
      S3db::Configuration.should_receive(:new).at_least(1).and_return(double("the configuration").as_null_object)
      S3db::Fetcher.new
    end
  end

  describe "fetch" do

    describe "at least one file with prefix 'mysql' are found" do

      it "uses the latest one" do
        stub_file_open
        fetcher.storage.stub(:list_files).and_return([
                                              {:key => "older-dump", :last_modified => "2012-10-26 00:00:00"},
                                              {:key => "latest-dump", :last_modified => "2012-10-27 00:00:00"}
                                          ])
        fetcher.storage.should_receive(:retrieve_object).with(anything, "latest-dump")
        fetcher.fetch
      end

      it "downloads the dump" do
        stub_file_open
        fetcher.storage.stub(:list_files).and_return([{:key => anything}])
        fetcher.storage.should_receive(:retrieve_object).with(anything, anything)
        fetcher.fetch
      end

      it "writes the downloaded dump to a file" do
        fetcher.storage.stub(:list_files).and_return([{:key => anything}])
        File.should_receive(:open).with(anything, "w+b")
        fetcher.fetch
      end

      it "decrypts the latest dump" do
        fetcher.should_receive(:system).with("rm -f ./db/latest_dump.sql.gz && ccrypt -k ./db/secret.txt -d ./db/latest_dump.sql.gz.cpt")
        fetcher.fetch
      end

      it "decompresses the latest dump" do
        fetcher.should_receive(:system).with("cd db && gunzip -f ./db/latest_dump.sql.gz")
        fetcher.fetch
      end

      describe "decompression fails" do
        it "raises an error" do
          fetcher.stub(:system => false)
          expect { fetcher.fetch }.to raise_error("Gunzipping './db/latest_dump.sql.gz' failed with exit code: false")
        end
      end

      describe "downloaded file not existing when trying to decompress" do
        it "raises an error" do
          File.stub(:exists?).with('./db/latest_dump.sql.gz').and_return(false)
          expect { fetcher.fetch }.to raise_error("./db/latest_dump.sql.gz not found")
        end
      end
    end

    describe "no latest dump with prefix 'mysql' found" do
      it "raises an error" do
        fetcher.storage.stub(:list_files).and_return(nil)
        expect { fetcher.fetch }.to raise_error("No file with prefix 'mysql' found in bucket 's3db_backup_production_bucket'")
      end
    end

    describe "S3DB_BUCKET not set" do
      it "uses the production bucket by default" do
        fetcher.storage.should_receive(:list_files).with("s3db_backup_production_bucket", {:prefix => "mysql"}).and_return([:key => "mysql-bla"])
        fetcher.fetch
      end
    end

    describe "S3DB_BUCKET env set" do
      it "uses the env variable value as bucket name" do
        ENV['S3DB_BUCKET'] = "a-bucket"
        fetcher.storage.should_receive(:list_files).with("a-bucket", {:prefix => "mysql"}).and_return([:key => "mysql-bla"])
        fetcher.fetch
        ENV['S3DB_BUCKET'] = nil
      end
    end
  end
end
