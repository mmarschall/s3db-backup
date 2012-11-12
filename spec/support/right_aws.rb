def stub_right_aws
  aws = mock(RightAws::S3Interface)
  RightAws::S3Interface.stub(:new).and_return(aws)
  aws.stub(:put)
  aws.stub(:list_files).and_return([:key => "mysql-bla"])
  aws
end