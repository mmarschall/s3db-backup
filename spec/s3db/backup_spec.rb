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