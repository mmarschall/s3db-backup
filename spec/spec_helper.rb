$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }
require 's3db-backup'