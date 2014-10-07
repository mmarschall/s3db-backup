def s3_config_yml_contents
  {
      "test" => {"bucket" => "s3db_backup_test_bucket"},
      "production" => {"bucket" => "s3db_backup_production_bucket"},
      "secret_access_key" => "secret_access_key",
      "aws_access_key_id" => "access_key_id",
      "max_num_backups" => 2
  }
end

def stub_s3_config_yml
  YAML.stub(:load_file => s3_config_yml_contents)
end