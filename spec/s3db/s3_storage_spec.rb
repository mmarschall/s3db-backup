require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::S3Storage do

  let!(:aws) { stub_right_aws }
  let(:s3) { S3db::S3Storage.new(S3db::Configuration.new) }

  before do
    stub_configuration
    s3.stub(:puts)
  end

  describe "initialize" do
    it "opens a connection to the S3 storage" do
      RightAws::S3Interface.should_receive(:new)
      S3db::S3Storage.new(S3db::Configuration.new)
    end
  end

  describe "retrieve_object" do
    it "delegates the call to the s3 connection" do
      aws.should_receive(:retrieve_object)
      s3.retrieve_object(anything, anything)
    end

    it "calls the given block to handle the incoming data chunks" do
      s3.should_receive(:retrieve_object).and_yield
      s3.retrieve_object(anything, anything) {}
    end
  end

  describe "list_files" do
    it "delegates the call to the s3 connection" do
      aws.should_receive(:list_bucket)
      s3.list_files(anything, anything)
    end
  end

  describe "put" do

    before do
      File.stub(:open)
    end

    it "delegates the call to the s3 connection" do
      aws.should_receive(:put)
      s3.put(anything, anything, Tempfile.new("bla"))
    end
  end
end