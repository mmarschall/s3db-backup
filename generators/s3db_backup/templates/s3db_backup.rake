require 'right_aws'
require 'progressbar'
require 's3db-backup'

namespace :db do
  namespace :seed do
    desc "fetch the latest prodcution dump from our Amazon S3 remote backup"
    task :fetch => :environment do
      S3DbBackup.fetch
    end

    desc "load the seed data from db/latest_prod_dump.sql.gz into the database and anonymize it"
    task :load => :environment do
      S3DbBackup.load
    end

    desc "anonymize data from your production dump"
    task :anonymize => :environment do
      S3DbBackup.anonymize
    end
  end
end