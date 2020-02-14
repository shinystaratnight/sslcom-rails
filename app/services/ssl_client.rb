class SslClient
  attr_reader :url, :port

  def initialize(url, port = '443')
    @url = url
    @port = port
  end

  def ping_for_certificate_info
    context = OpenSSL::SSL::SSLContext.new
    tcp_client = TCPSocket.new(url, port)
    ssl_client = OpenSSL::SSL::SSLSocket.new tcp_client, context
    ssl_client.hostname = url
    ssl_client.sync_close = true
    ssl_client.connect
    certificate = ssl_client.peer_cert
    verify_result = ssl_client.verify_result
    tcp_client.close
    {certificate: certificate, verify_result: verify_result }
  rescue => error
    {certificate: nil, verify_result: nil }
  end
end

# Note: This url https://clouddocs.f5.com/api/irules/SSL__verify_result.html shows
# the various 'verify_result' codes.
