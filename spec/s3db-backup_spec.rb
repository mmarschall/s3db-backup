require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "S3dbBackup" do



  describe ".backup" do

    let(:backup) { double("backup") }

    before do
      S3dbBackup.stub(:backup_instance => backup)
    end

    it "calls the backup method on the backup instance" do
      backup.should_receive(:backup)
      S3dbBackup.backup
    end
  end

  describe ".fetch" do

    let(:fetcher) { double("fetcher") }

    it "calls the fetch method on the fetcher instance" do
      fetcher.should_receive(:fetch)
      S3dbBackup.fetch
    end
  end

  describe ".load" do

    let(:loader) { double("loader") }

    it "calls the load method on the loader instance" do
      loader.should_receive(:load)
      S3dbBackup.load
    end
  end

  describe ".anonymize" do

    let(:loader) { double("loader") }

    it "calls the load method on the loader instance" do
      loader.should_receive(:anonymize_database)
      S3dbBackup.anonymize
    end
  end
end
