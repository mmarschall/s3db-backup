class S3dbBackupGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      m.template "s3_config.yml.erb", "config/s3_config.yml"
      m.file "s3db_backup.rake", "lib/tasks/s3db_backup.rake"
      m.file "secret.txt", "db/secret.txt"
    end
  end
end