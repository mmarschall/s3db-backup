require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
require 'pry'


describe S3db::Deleter do

  let(:deleter) { S3db::Deleter.new }
  let!(:aws) { stub_right_aws }
  let(:dumps) {[   {:key => "oldest-dump", :last_modified => "2012-10-25 00:00:00"},
                                              {:key => "older-dump", :last_modified => "2012-10-26 00:00:00"},
                                              {:key => "latest-dump", :last_modified => "2012-10-27 00:00:00"}
                                          ]}

  before do
    stub_configuration
    
    aws.stub(:list_bucket).and_return(dumps)
    deleter.stub(:s3).and_return(aws)
  end

  describe "attributes" do
    it "has reader for config" do
      deleter.config.should be_a(S3db::Configuration)
    end
    it "has reader for max_num_backups" do
      deleter.max_num_backups.should == 2
    end
    it "has reader for bucket" do
      deleter.bucket.should == "s3db_backup_production_bucket"
    end
  end

  describe "initialize" do
    it "instantiates a configuration instance" do
      S3db::Configuration.should_receive(:new).and_return(double("the configuration").as_null_object)
      S3db::Deleter.new
    end
  end
  
  describe "max_num_backups set" do
    describe "all_dumps" do
      it "lists 3 dumps" do
        deleter.all_dumps.length.should == 3
      end
    end
    
    describe "deletable_dumps" do
      it "lists just 1 dump as deletable" do
        deleter.deletable_dumps.length.should == 1
      end
    end
    
    describe "delete_dumps" do
      it "calls delete on the 1 oldest dump" do
        aws.should_receive(:delete).with(anything, "oldest-dump")
        deleter.clean
      end
    end
  end
  
  describe "max_num_backups not set" do
    it "should not call open_s3_connection" do
      deleter.stub(:max_num_backups).and_return(nil)
      deleter.should_not_receive(:open_s3_connection)
      deleter.clean
    end
    
    it "should not call delete_extra_dumps" do
      deleter.stub(:max_num_backups).and_return(nil)
      deleter.should_not_receive(:delete_extra_dumps)
      deleter.clean
    end
  end

  describe "all_dumps" do

    describe "S3DB_BUCKET not set" do
      it "uses the production bucket by default" do
        aws.should_receive(:list_bucket).with("s3db_backup_production_bucket", {:prefix => "mysql"})
        deleter.all_dumps
      end
    end
    
    describe "S3DB_BUCKET env set" do
      it "uses the env variable value as bucket name" do
        ENV['S3DB_BUCKET'] = "a-bucket"
        deleter = S3db::Deleter.new
        deleter.stub(:s3).and_return(aws)
        aws.should_receive(:list_bucket).with("a-bucket", {:prefix => "mysql"})
        deleter.all_dumps
        ENV['S3DB_BUCKET'] = nil
      end
    end

  end
end