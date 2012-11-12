require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
describe S3db::CommandLine do

  let(:command_line) { S3db::CommandLine.new(S3db::Configuration.new) }

  before do
    stub_configuration
    command_line.stub(:find_executable).and_return { |args| args }
  end

  describe "dump_command" do

    let(:tempfile) { stub(:path => "/foobar") }

    it "includes mysqldump into the command" do
      command_line.dump_command(tempfile).should =~ /mysqldump --user=app --password=secret s3db_backup_test/
    end

    it "includes gzip into the command" do
      command_line.dump_command(tempfile).should =~ /gzip -9/
    end

    it "includes ccrypt into the command" do
      command_line.dump_command(tempfile).should =~ /ccrypt -k \.\/db\/secret.txt -e > .*/
    end

    it "chains mysqldump, gzip, and ccrypt together" do
      command_line.dump_command(tempfile).should =~ /.*mysqldump.* \| .*gzip.* \| .*ccrypt.*/
    end
  end

  describe "load_command" do

    let(:latest_dump) { File.join(Rails.root, "db", "latest_prod_dump.sql") }

    it "includes mysql into the command" do
      command_line.load_command(anything).should =~ /mysql --user=app --password=secret --database=s3db_backup_test/
    end

    describe "db host and port are given" do
      before do
        configurations = rails_configurations['test'].merge!({'host' => 'myhost', 'port' => '8009'})
        command_line.config.stub(:db => configurations)
      end

      it "includes host into the command" do
        command_line.load_command(anything).should =~ /--host=myhost/
      end

      it "includes port into the command" do
        command_line.load_command(anything).should =~ /--port=8009/
      end
    end

    describe "password not given" do
      it "excludes password from the command" do
        configurations = rails_configurations['test'].tap { |c| c.delete('password') }
        command_line.config.stub(:db => configurations)
        command_line.load_command(anything).should_not =~ /--password=/
      end
    end
  end
end