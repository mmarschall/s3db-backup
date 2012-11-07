def stub_configuration
  stub_rails
  stub_s3_config_yml
  File.stub(:exists?).with("./db/secret.txt").and_return(true)
end
