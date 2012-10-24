module Rails
end

module ActiveRecord
  class Base
  end
end

def stub_rails
  Rails.stub(:root => ".")
  Rails.stub(:env => 'test')
  ActiveRecord::Base.stub(:configurations => {
      'test' => {
          "username" => "app",
          "encoding" => "utf8",
          "database" => "s3db_backup_test",
          "password" => "secret",
          "adapter" => "mysql2"
      }
  })
end