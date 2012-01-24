<%@page language="java" %>
<html>
<head>
<title>SSL Resources - Find Support, FAQ's, and Other Information Here</title>
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
          <p><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1"><b><br>
            </b></font> </p></td>
        <td class=footerLine width=1><img height=109 alt=""
      src="../images/shim.gif" width=1 border=0></td>
        <td width=18><img height=8 alt="" src="../images/shim.gif"
      width=18 border=0></td>
        <td width=80% valign=top>
          <table bgcolor=#012f8b width="100%" border="0">
            <tr>
              <td width="100%"><img src="../images/resourcesH1.gif" width="139" height="26" vspace="11"></td>
            </tr>
            <tr>
              <td align="center">

              <table width="95%" border="0" cellpadding="0" align="right">
                <tr>
                  <td><img src="../images/support.gif" width="59" height="11" vspace="4"><br>
                    <table width="95%" border="0" cellpadding="4" align="center">
                      <tr> 
                        <td> <font size="1" color="c5e1ff"><b>Installing your 
                          Certificate on a C2Net Stronghold </b><br>
                          Note: You must install both the bundle CA certificate 
                          and your server certificate to provide secure access 
                          to your Web server. </font> 
                          <p><font size="1" color="c5e1ff"><span class="hyperlink"><a href="/support/cacerts/ca_new.txt">Get 
                            bundle CA file</a></span></font></p>
                          <p><font size="1" color="c5e1ff">On startup, Stronghold 
                            loads CA certificates from the file specified by the 
                            SSLCACertificateFile entry in its 'httpd.conf' file.</font></p>
                          <ul>
                            <li><font size="1" color="c5e1ff">To install the bundle 
                              CA certificate, reference it in the httpd.conf file. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">Ensure that you 
                              have saved the bundle CA certificate as a text file. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">Open your 'httpd.conf' 
                              file and find the SSLCACertificateFile entry. By 
                              default the entry will be SSLCACertificateFile='/ssl/CA/client-rootcerts.pem'. 
                              You will find 'httpd.conf' in the directory /conf. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">Open the file identified 
                              by SSLCACertificateFile (for example, /ssl/CA/client-rootcerts.pem) 
                              in a text editor. </font></li>
                            <li><font size="1" color="c5e1ff">Open the file that 
                              contains the bundle CA certificate (ca_new.txt) 
                              in a text editor. <br>
                              Copy the bundle CA certificate (including the '-----BEGIN 
                              CERTIFICATE-----' and '-----END CERTIFICATE-----' 
                              lines to the clipboard. </font></li>
                            <li><font size="1" color="c5e1ff">Paste the bundle 
                              CA certificate into the file identified by SSLCACertificateFile. 
                              In most cases you will want to insert the bundle 
                              CA certificate at the end of the file and add a 
                              comment to identify the certificate. </font></li>
                            <li><font size="1" color="c5e1ff">Save the modified 
                              file and close the text editor. </font></li>
                            <li><font size="1" color="c5e1ff">Restart your web 
                              server. </font></li>
                          </ul>
                          <p><font size="1" color="c5e1ff">To install your server 
                            certificate:</font></p>
                          <ul>
                            <li><font size="1" color="c5e1ff">Save your server 
                              certificate as a text file. </font></li>
                            <li><font size="1" color="c5e1ff">Install the new 
                              certificate using getca, this utility is normally 
                              installed in /bin:<br>
                              <br>
                              </font><font size="1" color="c5e1ff">getca myhostname 
                              &lt; /server certificate file location and name<br>
                              Where: myhostname is the common name of the Web 
                              server for which the certificate was requested (this 
                              is the same as specified when you ran genkey) and 
                              '/server certificate file location and name' is 
                              the name of the server certificate file. This will 
                              save the certificate in the file /ssl/certs/myhostname.cert.</font></li>
                            <li><font size="1" color="c5e1ff">Restart your web 
                              server.</font></li>
                          </ul>
                          <p></p>
                        </td>
                      </tr>
                      <tr>
                        <td>&nbsp;</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
              </td>
            </tr>
          </table>
      </tbody>
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
