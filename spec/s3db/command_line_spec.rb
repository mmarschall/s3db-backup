require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))
describe S3db::CommandLine do

  before do
    stub_configuration
  end

  let(:commandline) { S3db::CommandLine.new(S3db::Configuration.new, stub(:path => "/foobar")) }

  describe "dump_command" do
    it "includes mysqldump into the command" do
      commandline.dump_command.should =~ /mysqldump --user=app --password=secret s3db_backup_test/
    end

    it "includes gzip into the command" do
      commandline.dump_command.should  =~ /gzip -9/
    end

    it "includes ccrypt into the command" do
      commandline.dump_command.should =~ /ccrypt -k \.\/db\/secret.txt -e > .*/
    end

    it "chains mysqldump, gzip, and ccrypt together" do
      commandline.dump_command.should =~ /.*mysqldump.* \| .*gzip.* \| .*ccrypt.*/
    end
  end
end