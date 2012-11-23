require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe S3db::Configuration do

  before do
    stub_configuration
  end

  describe "initialize" do

    context "without environment S3DB_DATABASE_CONFIG" do
      it "loads the db config for the current RAILS_ENV" do
        config = S3db::Configuration.new
        config.db.should == rails_configurations['test']
      end
    end

    context "with environment S3DB_DATABASE_CONFIG" do
      it "loads the db config identified by the env variable" do
        ENV['S3DB_DATABASE_CONFIG'] = "other_db_config"
        config = S3db::Configuration.new
        config.db.should == rails_configurations['other_db_config']
        ENV['S3DB_DATABASE_CONFIG'] = nil
      end
    end

    it "loads the aws config" do
      config = S3db::Configuration.new
      config.aws.should == s3_config_yml_contents.merge({'bucket' => 's3db_backup_test_bucket'})
    end

    describe "handling of missing keys in s3_config.yml" do
      context "when AWS authentication key is missing" do
        it "throws AwsConfigurationError" do
          should_raise_error_if_missing_key('aws_access_key_id')
          should_raise_error_if_missing_key('secret_access_key')
        end
      end

      context "when environment section is missing" do
        it "throws AwsConfigurationError" do
          should_raise_error_if_missing_key('test')
        end
      end

      context "when bucket is missing in the section identified by current RAILS_ENV" do
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

