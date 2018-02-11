module LiveServerMock
  def self.stub_all(webmock)
    webmock.stub_request(:get, 'example.com/echo')
  end
end