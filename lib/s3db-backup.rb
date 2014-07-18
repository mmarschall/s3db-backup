require "right_aws"
require "yaml"
require "tempfile"
require "s3db/backup"
require "s3db/fetcher"
require "s3db/loader"
require "s3db/deleter"

class S3dbBackup

  def self.backup_instance
    S3db::Backup.new
  end

  def self.fetcher
    S3db::Fetcher.new 
  end
  
  def self.deleter
    S3db::Deleter.new
  end

  def self.loader
    S3db::Loader.new
  end

  # this class method is needed for backward compatibility <= 0.6.4
  def self.backup
    backup_instance.backup
    cleanup
  end

  # this class method is needed for backward compatibility <= 0.6.4
  def self.fetch
    fetcher.fetch
  end

  # this class method is needed for backward compatibility <= 0.6.4
  def self.load
    loader.load
  end
  
  def self.clean
    deleter.clean
  end

  def self.anonymize
    loader.anonymize_database
  end

  # this class method needs to live here for backward compatibility <= 0.6.4
  # The <= 0.6.4 way of customizing the anonymization was to open S3dbBackup
  # and redefine this method
  def self.anonymize_dump(config, connection)
  end
end
