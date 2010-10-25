require 's3db-backup'

namespace :s3db do
  
  desc "conduct a backup and upload it to Amazon S3"
  task :backup => :environment do
    S3dbBackup.backup
  end
  
  namespace :latest do
    desc "fetch the latest prodcution dump from our Amazon S3 remote backup"
    task :fetch => :environment do
      S3dbBackup.fetch
    end

    desc "load the seed data from db/latest_prod_dump.sql.gz into the database and anonymize it"
    task :load => :environment do
      S3dbBackup.load
    end

    desc "anonymize data from your production dump"
    task :anonymize => :environment do
      S3dbBackup.anonymize
    end    
  end
  
  desc "synchronize files from shared/system to your Amazon S3 bucket"
  task :sync_public_system_files => :environment do
    S3dbBackup.sync_public_system_files
  end
  
end