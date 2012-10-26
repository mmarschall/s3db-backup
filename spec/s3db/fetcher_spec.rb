require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Fetcher do

  let(:fetcher) { S3db::Fetcher.new }
  let!(:aws) { stub_right_aws() }

  before do
    stub_configuration

    File.stub(:open)
    File.stub(:exist?).with('./db/latest_prod_dump.sql.gz').and_return(true)

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