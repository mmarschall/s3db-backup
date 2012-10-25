require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "S3dbBackup" do

  let(:backup) { double("backup") }

  before do
    S3dbBackup.stub(:backup_instance => backup)
  end

  describe ".backup" do
    it "calls the backup method on the backup instance" do
      backup.should_receive(:backup)
      S3dbBackup.backup
    end
  end
end
