require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Configuration do

  before do
    stub_configuration
  end

  describe "initialize" do
    it "loads the db config" do
      config = S3db::Configuration.new
      config.db.should == rails_configurations['test']
    end

    it "loads the aws config" do
      config = S3db::Configuration.new
      config.aws.should == s3_config_yml_contents.merge({'bucket' => 's3db_backup_test_bucket'})
    end

    it "sets the latest_dump_path" do
      config = S3db::Configuration.new
      config.latest_dump_path.should eql(File.join(::Rails.root, 'db', 'latest_dump.sql'))
    end

    describe "s3 config yml" do
      describe "first-level key is missing" do
        it "throws AwsConfigurationError" do
          should_raise_error_if_missing_key('test')
          should_raise_error_if_missing_key('aws_access_key_id')
          should_raise_error_if_missing_key('secret_access_key')
        end
      end

      describe "bucket is missing" do
        it "throws AwsConfigurationError" do
          incomplete_s3_config = s3_config_yml_contents
          env_config = incomplete_s3_config['test']
          env_config.delete('bucket')
          incomplete_s3_config['test'] = env_config
          YAML.stub(:load_file => incomplete_s3_config)

          expect { S3db::Configuration.new }.to raise_error(S3db::AwsConfigurationError, /bucket/)
        end
      end
    end

  end
end

def should_raise_error_if_missing_key(key)
  incomplete_s3_config = s3_config_yml_contents
  incomplete_s3_config.delete(key)
  YAML.stub(:load_file => incomplete_s3_config)

  expect { S3db::Configuration.new }.to raise_error(S3db::AwsConfigurationError, /#{key}/)
end

