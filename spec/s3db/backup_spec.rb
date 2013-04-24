require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Backup do

  let(:backup) { S3db::Backup.new }

  before do
    stub_configuration
    backup.stub(:system)
    backup.storage = stub_storage
  end

  describe "attributes" do
    it "has reader for config" do
       backup.config.should be_a(S3db::Configuration)
    end
    it "has reader for encrypted_file" do
       backup.encrypted_file.should be_a(Tempfile)
    end
  end

  describe "initialize" do
    it "instantiates a configuration instance" do
      S3db::Configuration.should_receive(:new).at_least(1)
      S3db::Backup.new
    end

    it "creates a Tempfile for the dump" do
      Tempfile.should_receive(:new)
      S3db::Backup.new
    end
  end

  describe "backup" do
    it "uploads encrypted and compressed database dump to given S3 bucket" do
      backup.storage.should_receive(:connect)
      backup.storage.should_receive(:put_object)
      backup.backup
    end
  end
end
