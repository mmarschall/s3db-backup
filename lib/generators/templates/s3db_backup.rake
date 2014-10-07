require 's3db-backup'

namespace :s3db do
  
  desc "conduct a backup and upload it to Amazon S3"
  task :backup => :environment do
    S3dbBackup.backup
  end
  
  desc "clean old backups based on the max num of backups specified in s3_config.yml"
  task :clean => :environment do
    S3dbBackup.clean
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
end