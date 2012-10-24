require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "S3dbBackup" do
  before do
    stub_rails()
    stub_s3_config_yml()
    stub_right_aws()
    S3dbBackup.stub(:system)
  end

  describe "backup" do
    it "includes mysqldump into the command to run" do
      S3dbBackup.should_receive(:system).with(/mysqldump --user=app --password=secret s3db_backup_test/)
      S3dbBackup.backup
    end

    it "includes gzip into the command to run" do
      S3dbBackup.should_receive(:system).with(/gzip -9/)
      S3dbBackup.backup
    end

    it "includes ccrypt into the command to run" do
      S3dbBackup.should_receive(:system).with(/ccrypt -k \.\/db\/secret.txt -e > .*/)
      S3dbBackup.backup
    end

    it "uploads encrypted and compressed database dump to given S3 bucket" do
      @aws.should_receive(:put)
      S3dbBackup.backup
    end
  end
end