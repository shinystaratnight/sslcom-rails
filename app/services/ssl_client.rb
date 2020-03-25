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
    Socket.tcp(url, port, connect_timeout: 3) do |socket|
      ssl_client = OpenSSL::SSL::SSLSocket.new socket, context
      ssl_client.hostname = url
      ssl_client.sync_close = true
      ssl_client.connect
      certificate = ssl_client.peer_cert
      socket.close
      certificate
    end
  rescue Errno::ETIMEDOUT
    nil
  end

  def verify_result
    result = %x"echo QUIT | timeout 3 openssl s_client -CApath /etc/ssl/certs/ -servername #{url} -verify_hostname #{url} -connect #{url}:#{port}"
    result.match(/Verify return code: (.*)/)[1].scan(/\(([^\)]+)\)/).flatten[0].downcase
  rescue
    nil
  end
end
