require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::EncryptionKey do

  before do
    stub_configuration
  end

  describe "S3DB_SECRET_KEY_PATH env variable not set" do
    it "uses the default" do
      S3db::EncryptionKey.path.should == "./db/secret.txt"
    end
  end

  describe "S3DB_SECRET_KEY_PATH env variable is set" do

    before do
      ENV['S3DB_SECRET_KEY_PATH'] = "my/path"
      File.stub(:exists?).with("my/path").and_return(true)
    end

    it "uses the value of the env variable" do
      S3db::EncryptionKey.path.should == "my/path"
    end

    after do
      ENV['S3DB_SECRET_KEY_PATH'] = nil
    end
  end

  describe "file does not exist" do

    before do
      File.stub(:exists?).with("./db/secret.txt").and_return(false)
    end

    it "raises an error" do
      expect { S3db::EncryptionKey.path }.to raise_error("Please make sure you put your secret encryption key into: './db/secret.txt'")
    end
  end
end