module Rails
end

module ActiveRecord
  class Base
  end
end

def stub_rails
  Rails.stub(:root => ".")
  Rails.stub(:env => 'test')
  ActiveRecord::Base.stub(:configurations => rails_configurations)
  ActiveRecord::Base.stub(:connection => double("the connection").as_null_object)
  ActiveRecord::Base.stub(:establish_connection => double("the established connection").as_null_object)
end

def rails_configurations
  {
      'test' => {
          "username" => "app",
          "encoding" => "utf8",
          "database" => "s3db_backup_test",
          "password" => "secret",
          "adapter" => "mysql2"
      },
      'other_db_config' => {
        "username" => "my_app",
        "encoding" => "utf8",
        "database" => "my_other_db",
        "password" => "another_secret",
        "adapter" => "mysql2"
      }
  }
end