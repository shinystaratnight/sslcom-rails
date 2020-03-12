class SslClient
  attr_reader :url, :port

  def initialize(url, port = '443')
    @url = url
    @port = port
  end

  def retrieve_x509_cert
    cert_store = OpenSSL::X509::Store.new
    cert_store.set_default_paths
    context = OpenSSL::SSL::SSLContext.new
    context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    context.cert_store = cert_store
    tcp_client = TCPSocket.new(url, port)
    ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
    ssl_client.hostname = url
    ssl_client.sync_close = true
    ssl_client.connect
    certificate = ssl_client.peer_cert
    tcp_client.close
    certificate
  rescue
    nil
  end

  def verify_result
    result = %x"echo QUIT | openssl s_client -CApath /etc/ssl/certs/ -servername #{url} -verify_hostname #{url} -connect #{url}:#{port}"
    result.match(/Verify return code: (.*)/)[1]
  rescue
    nil
  end
end
