def stub_storage
  storage = double(S3db::Storage)
  storage.stub(:connect)
  storage.stub(:list_files).and_return([:key => "mysql-bla"])
  storage
end
