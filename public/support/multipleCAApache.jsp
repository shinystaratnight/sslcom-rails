<%@page language="java" %>
<html>
<head>
<title>SSL Support - Enrollment And Installation Instructions</title>
<meta http-equiv=Content-Type content="text/html; charset=iso-8859-1">
<link href="/styles/global_style.css" type=text/css rel=stylesheet>
</head>
<body text=black vlink=#003366 alink=#333333 link=#012f8b bgcolor=#0b439e
topmargin=0>
  <div align=center>
    <!-- /scripts/header.jsp begin -->
    <jsp:include page="/scripts/header.jsp" flush="true"/>
    <!-- /scripts/header.jsp end -->
    <!-- /scripts/infoBar.jsp begin -->
    <jsp:include page="/scripts/infoBar.jsp" flush="true"/>
    <!-- /scripts/infoBar.jsp end -->
    <table class=footerBg cellspacing=0 cellpadding=0 width=700 border=0>
      <tbody>
      <tr>
        <td align=middle colspan=7>&nbsp;</td>
      </tr>
      <tr>
        <td class=footerLine colspan=7 height=1><img height=1 alt=""
      src="../images/shim.gif" width=1 border=0></td>
      </tr>
      <tr>
        <td width=13><img height=1 alt="" src="../images/shim.gif"
      width=27 border=0></td>
        <td width=19% valign="top">
          <!-- /scripts/resourcesNav.jsp begin -->
          <jsp:include page="/scripts/resourcesNav.jsp" flush="true"/>
          <!-- /scripts/resourcesNav.jsp end -->
          <p>&nbsp;</p>
          <!-- /scripts/pageComments.jsp begin -->
          <jsp:include page="/scripts/pageComments.jsp" flush="true"/>
          <!-- /scripts/pageComments.jsp end -->
        <p><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1">
          <b><br></b></font></p></td>
        <td class=footerLine width=1><img height=109 alt=""
      src="../images/shim.gif" width=1 border=0></td>
        <td width=18><img height=8 alt="" src="../images/shim.gif"
      width=18 border=0></td>
        <td width=80% valign=top>
          <table bgcolor=#012f8b width="100%" border="0">
            <tr>
              <td width="100%"><img src="../images/supportH1.gif" width="110" height="26" vspace="11"></td>
            </tr>
            <tr>
              <td align="center">
                <table width="95%" border="0" cellpadding="0" align="right">
                  <tr>
                    
                  <td><img src="/images/serverCertInstallation.gif" width="249" height="11" vspace="4"><br>
                      
                    <table width="95%" border="0" cellpadding="4" align="center">
                      <tr> 
                        <td> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Installing 
                            multiple Certification Authorities on a <br>
                            single Apache webserver</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                            run more than one Certificate Authority on the Apache 
                            web server the configuration must look something like 
                            the details below. Please note the SSLCACertificateFile 
                            lines referencing 2 different bundle files which give 
                            2 different root authorities. Please also note the 
                            virtual host delimiter &lt;/VirtualHost&gt; which 
                            keeps the details for each virtual host separate.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">### 
                            Section 3: Virtual Hosts</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&lt;IfDefine 
                            HAVE_SSL&gt;</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">## 
                            SSL Virtual Host Context</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&lt;VirtualHost 
                            192.168.0.20:443&gt;<br>
                            DocumentRoot &quot;/var/www/html2&quot;<br>
                            ServerName apache2.ssl.com<br>
                            ErrorLog logs/error_log<br>
                            TransferLog logs/access_log<br>
                            SSLEngine on<br>
                            SSLCertificateFile /etc/httpd/conf/apache.ssl/server.crt<br>
                            SSLCertificateKeyFile /etc/httpd/conf/apache.ssl/myserver.key<br>
                            SSLCACertificateFile /etc/httpd/conf/apache.ssl/ca.txt<br>
                            SSLOptions +FakeBasicAuth +ExportCertData +CompatEnvVars 
                            +StrictRequire<br>
                            SetEnvIf User-Agent &quot;.*MSIE.*&quot; \<br>
                            nokeepalive ssl-unclean-shutdown \<br>
                            downgrade-1.0 force-response-1.0<br>
                            CustomLog logs/ssl_request_log \<br>
                            &quot;%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \&quot;%r\&quot; 
                            %b&quot;</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&lt;/VirtualHost&gt; 
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&lt;VirtualHost 
                            192.168.0.21:443&gt;<br>
                            DocumentRoot &quot;/var/www/html2&quot;<br>
                            ServerName apache2.ssl.com<br>
                            ErrorLog logs/error_log<br>
                            TransferLog logs/access_log<br>
                            SSLEngine on<br>
                            SSLCertificateFile /etc/httpd/conf/apache2.ssl/server.crt<br>
                            SSLCertificateKeyFile /etc/httpd/conf/apache2.ssl/myserver.key<br>
                            SSLCACertificateFile /etc/httpd/conf/apache2.ssl/other-bundle.txt<br>
                            SSLOptions +FakeBasicAuth +ExportCertData +CompatEnvVars 
                            +StrictRequire<br>
                            SetEnvIf User-Agent &quot;.*MSIE.*&quot; \<br>
                            nokeepalive ssl-unclean-shutdown \<br>
                            downgrade-1.0 force-response-1.0<br>
                            CustomLog logs/ssl_request_log \<br>
                            &quot;%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \&quot;%r\&quot; 
                            %b&quot;</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&lt;/VirtualHost&gt;<br>
                            </font></p>
                        </td>
                      </tr>
                    </table>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
    </table>
    <!-- /scripts/footerBar.jsp begin -->
    <jsp:include page="/scripts/footerBar.jsp" flush="true"/>
    <!-- /scripts/footerBar.jsp end -->
    <!-- /scripts/footer.jsp begin -->
    <jsp:include page="/scripts/footer.jsp" flush="true"/>
    <!-- /scripts/footer.jsp end -->
</div>
</body>
</html>
