require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))


describe S3db::Loader do

  let(:loader) { S3db::Loader.new }

  before do
    stub_configuration

    loader.stub(:system => 0)
    loader.stub(:puts)
  end

  describe "attributes" do
    it "has reader for config" do
      loader.config.should be_a(S3db::Configuration)
    end
    it "has reader for latest_dump_path" do
      loader.latest_dump_path.should == './db/latest_prod_dump.sql'
    end
  end

  describe "initialize" do
    it "instantiates a configuration instance" do
      S3db::Configuration.should_receive(:new)
      S3db::Loader.new
    end
  end

  describe "load" do

    it "recreates the database" do
      loader.stub(:command_line => double("the command line").as_null_object)

      ActiveRecord::Base.connection.should_receive(:recreate_database).with(loader.config.db['database'], loader.config.db)
      loader.load
    end

    it "executes the mysql load command" do
      command_line = S3db::CommandLine.new(loader.config)
      command_line.stub(:find_executable).and_return { |args| args }
      loader.stub(:command_line).and_return(command_line)

      loader.should_receive(:system).with(/mysql/)
      loader.load
    end
  end

  describe "anonymize_database" do

  end
end