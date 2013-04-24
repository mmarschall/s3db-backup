require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Storage do

  let(:storage) { S3db::Storage.new }

  before do
    stub_configuration
    stub_right_aws
  end

  describe "connect" do
    it "instantiates a connection to the cloud storage" do
      connection = storage.connect
      connection.should be_a(double(RightAws::S3Interface).class)
    end
  end

  describe "list_files" do
    before do
      storage.connect
    end

    describe "bucket has files" do
      it "returns an array" do
        storage.list_files("any_bucket").should be_a(Array)
      end
    end

    describe "bucket has no matching files" do
      before do
        storage.connection.stub(:list_bucket).and_return(nil)
      end
      it "returns nil" do
        storage.list_files("any_bucket").should be(nil)
      end
    end
  end

  describe "retrieve_object" do
    before do
      storage.connect
    end
    it "yields the provided ruby block" do
      storage.should_receive(:retrieve_object).and_yield
      storage.retrieve_object("any_bucket") do
        "bla"
      end
    end
  end

  describe "put_object" do
    before do
      storage.connect
    end
    it "returns the given key" do
      storage.put_object("any_bucket", "my_key", double(File)).should eql("my_key")
    end
  end
end
