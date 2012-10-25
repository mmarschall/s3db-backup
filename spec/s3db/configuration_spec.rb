require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Configuration do

  before do
    stub_rails()
    stub_s3_config_yml()
  end

  it "load the db config" do
    config = S3db::Configuration.new
    config.db.should == rails_configurations['test']
  end
end

