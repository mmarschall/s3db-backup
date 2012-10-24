def stub_s3_config_yml
  YAML.stub(:load_file => {
      "test" => {"bucket" => "s3db_backup_test_bucket"},
      "secret_access_key" => "secret_access_key",
      "aws_access_key_id" => "access_key_id"
  })
end