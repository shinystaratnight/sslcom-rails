<%@page language="java" %>
<html>
<head>
<title>SSL Support - How To Generate a Certificate Signing Request(CSR)</title>
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
        <td align=middle colspan=10>&nbsp;</td>
      </tr>
      <tr>
        <td class=footerLine colspan=10 height=1><img height=1 alt=""
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
        <td width=51% valign=top>
          <table bgcolor=#012f8b width="100%" border="0">
            <tr>
              <td width="100%"><img src="../images/supportH1.gif" width="110" height="26" vspace="11"></td>
            </tr>
            <tr>
              <td align="center">
                <table width="95%" border="0" cellpadding="0" align="right">
                  <tr>
                    
                  <td><img src="../images/serverCertInstallation.gif" width="249" height="11" vspace="4"><br>

                    <table width="95%" border="0" cellpadding="4" align="center">
                      <tr> 
                        <td> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Installing 
                            your Certificate on Apache OpenSSL</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Step 
                            one: Copy your certificate to file</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                            will receive an email from SSL with the certificate 
                            in the email (yourdomainname.crt). When viewed in 
                            a text editor, your certificate will look something 
                            like:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">-----BEGIN 
                            CERTIFICATE-----<br>
                            MIAGCSqGSIb3DQEHAqCAMIACAQExADALBgkqhkiG9w0BB<br>
                            UbM77e50M63v1Z2A/5O5MA0GCSqGSIb3DQEOBAUAMF8x<br>
                            (.......)<br>
                            E+cFEpf0WForA+eRP6XraWw8rTN8102zGrcJgg4P6XVS4l39+l<br>
                            K99c42ku3QrlX2+KeDi+xBG2cEIsdSiXeQS/16S36ITclu4AAD<br>
                            -----END CERTIFICATE-----</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Copy 
                            your Certificate into the directory that you will 
                            be using to hold your certificates. In this example 
                            we will use /etc/ssl/crt/. Both the public and private 
                            key files will already be in this directory. The private 
                            key used in the example will be labeled private.key 
                            and the public key will be yourdomainname.crt. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">It 
                            is recommended that you make the directory that contains 
                            the private key file only readable by root. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Step 
                            two: Install the Intermediate Certificates</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                            will need to install the chain certificates (intermediates) 
                            in order for browsers to trust your certificate. As 
                            well as your SSL certificate (yourdomainname.crt) 
                            two other certificates, named GTECyberTrustGlobalRootCA.crt 
                            and ComodoClass3SecurityServicesCA.crt, are also attached 
                            to the email from SSL. Apache users will not require 
                            these certificates. Instead you can install the intermediate 
                            certificates using a 'bundle' method.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                            the Virtual Host settings for your site, in the httpd.conf 
                            file, you will need to complete the following:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">1. 
                            Copy this ca-bundle file to the same directory as 
                            httpd.conf (this contains all of the CA certificates 
                            in the chain).</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">2. 
                            Add the following line to SSL section of the httpd.conf 
                            (assuming /etc/httpd/conf is the directory to where 
                            you have copied the ca.txt file). if the line already 
                            exists amend it to read the following:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">SSLCACertificateFile 
                            /etc/httpd/conf/ca-bundle/ca_new.txt</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">If 
                            you are using a different location and certificate 
                            file names you will need to change the path and filename 
                            to reflect your server.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                            SSL section of the updated httpd config file should 
                            now read similar to this example (depending on your 
                            naming and directories used):</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">SSLCertificateFile 
                            /etc/ssl/crt/yourdomainname.crt </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">SSLCertificateKeyFile 
                            /etc/ssl/crt/private.key</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">SSLCACertificateFile 
                            /etc/httpd/conf/ca-bundle/ca.txt</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            Save your httpd.conf file and restart Apache.</font></p>
                          <p></p>
                        </td>
                      </tr>
                    </table>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </td>
        <td class=footerLine width=1><img height=109 alt=""
      src="../images/shim.gif" width=1 border=0></td>
        <td width=18><img height=8 alt="" src="../images/shim.gif"
      width=18 border=0></td>
        <td valign=top>
        <!-- /scripts/installServerList.jsp begin -->
        <jsp:include page="/scripts/installServerList.jsp" flush="true"/>
        <!-- /scripts/installServerList.jsp end -->
        </td>
        <td width=27><img height=1 alt="" src="../images/shim.gif"
      width=27 border=0></td>
      </tr>
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
