def stub_file_open
  file = double("a file")
  file.stub(:write)
  File.stub(:open).and_yield(file)
end
