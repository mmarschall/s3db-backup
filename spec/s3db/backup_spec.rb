require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Backup do

  let(:backup) { S3db::Backup.new }
  let!(:aws) { stub_right_aws() }

  before do
    stub_rails()
    stub_s3_config_yml()
    backup.stub(:system)
    File.stub(:exists?).with("./db/secret.txt").and_return(true)
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
      S3db::Configuration.should_receive(:new)
      S3db::Backup.new
    end

    it "creates a Tempfile for the dump" do
      Tempfile.should_receive(:new)
      S3db::Backup.new
    end
  end

  describe "backup" do
    it "includes mysqldump into the command to run" do
      backup.should_receive(:system).with(/mysqldump --user=app --password=secret s3db_backup_test/)
      backup.backup
    end

    it "includes gzip into the command to run" do
      backup.should_receive(:system).with(/gzip -9/)
      backup.backup
    end

    it "includes ccrypt into the command to run" do
      backup.should_receive(:system).with(/ccrypt -k \.\/db\/secret.txt -e > .*/)
      backup.backup
    end

    it "uploads encrypted and compressed database dump to given S3 bucket" do
      aws.should_receive(:put)
      backup.backup
    end
  end
end