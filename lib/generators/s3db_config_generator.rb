class S3dbConfigGenerator < Rails::Generators::Base
  source_root File.expand_path("../templates", __FILE__)

  def create_secret_txt
    create_file "db/secret.txt" do
      "my secret encryption key"
    end
  end

  def install_rake_file
    copy_file "s3db_backup.rake", "lib/tasks/s3db_backup.rake"
  end

  def create_s3_config_yml
    template "s3_config.yml.tt", "config/s3_config.yml"
  end
end