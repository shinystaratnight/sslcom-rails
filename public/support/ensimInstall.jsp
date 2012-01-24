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
                          Certificate on Apache via Ensim Webappliance 3.1.x </b></font> 
                          <p><font size="1" color="c5e1ff">Step one: Loading the 
                            Site Certificate</font></p>
                          <p><font size="1" color="c5e1ff">You will receive an 
                            email from SSL with the certificate in the email (yourdomainname.crt). 
                            When viewed in a text editor, your certificate will 
                            look something like:</font></p>
                          <p><font size="1" color="c5e1ff">-----BEGIN CERTIFICATE-----<br>
                            MIAGCSqGSIb3DQEHAqCAMIACAQExADALBgkqhkiG9w0BBwGggDCCAmowggHXAhAF<br>
                            (.......)<br>
                            K99c42ku3QrlX2+KeDi+xBG2cEIsdSiXeQS/16S36ITclu4AADEAAAAAAAAA<br>
                            -----END CERTIFICATE-----</font></p>
                          <p><font size="1" color="c5e1ff">Copy your Certificate 
                            into the directory that you will be using to hold 
                            your certificates. In this example we will use /etc/ssl/crt/. 
                            Both the public and private key files will already 
                            be in this directory. The private key used in the 
                            example will be labelled private.key and the public 
                            key will be yourdomainname.crt.</font></p>
                          <p><font size="1" color="c5e1ff">It is recommended that 
                            you make the directory that contains the private key 
                            file only readable by root. </font></p>
                          <p><font size="1" color="c5e1ff">Login to the Administrator 
                            console and select the site that the certificate was 
                            requested for.</font></p>
                          <p><font size="1" color="c5e1ff">Select Services, then 
                            Actions next to Apache Web Server and then SSL Settings. 
                            There should already be a 'Self Signed' certifcate 
                            saved.</font></p>
                          <p><img src="/images/support/install/ensim/ensim6.gif"></p>
                          <p><font size="1" color="c5e1ff">Select 'Import' and 
                            copy the text from the yourdomainname.crt file into 
                            the box</font></p>
                          <p><img src="/images/support/install/ensim/ensim7.gif" width="525" height="268"></p>
                          <p><font size="1" color="c5e1ff">Select 'Save', the 
                            status should now change to successful.</font></p>
                          <p><img src="/images/support/install/ensim/ensim8.gif"></p>
                          <p><font size="1" color="c5e1ff">Logout, do not select 
                            delete as this will delete the installed certificate.</font></p>
                          <p><font size="1" color="c5e1ff"><b>Step two: Install 
                            the Intermediate/Root Certificates</b></font></p>
                          <p><font size="1" color="c5e1ff">You will need to install 
                            the Intermediate and Root certificates in order for 
                            browsers to trust your certificate. As well as your 
                            SSL certificate ( <b>yourdomainname.crt</b>) two other 
                            certificates, named <b>GTECyberTrustRootCA.crt</b> 
                            and <b>ComodoClass3SecurityServicesCA.crt</b>, are 
                            also attached to the email from Comodo. Apache users 
                            will not require these certificates. Instead you can 
                            install the intermediate certificates using a 'bundle' 
                            method.</font></p>
                          <p><font size="1" color="c5e1ff"><span class="hyperlink"><a href="/support/cacerts/ca_new.txt">Download 
                            a Bundled cert file</a></span></font></p>
                          <p><font size="1" color="c5e1ff">In the Virtual Host 
                            settings for your site, in the virtual site file, 
                            you will need to add the following SSL directives. 
                            This may be achieved by:</font></p>
                          <p><font size="1" color="c5e1ff">1. Copy this ca-bundle 
                            file to the same directory as the certificate (this 
                            contains all of the ca certificates in the Comodo 
                            chain, exept the yourdomainname.crt).</font></p>
                          <p><font size="1" color="c5e1ff">2. Add the following 
                            line to the virtual host file under the virtual host 
                            domain for your site (assuming /etc/httpd/conf is 
                            the directory mentioned in 1.), if the line already 
                            exists amend it to read the following:</font></p>
                          <blockquote> 
                            <p><font size="1" color="c5e1ff">SSLCACertificateFile 
                              /etc/httpd/conf/ca-bundle/ca_new.txt</font></p>
                          </blockquote>
                          <p><font size="1" color="c5e1ff">If you are using a 
                            different location and certificate file names you 
                            will need to change the path and filename to reflect 
                            this.<br>
                            The SSL section of the updated virtual host file should 
                            now read similar to this example (depending on your 
                            naming and directories used):</font></p>
                          <blockquote>
                            <p><font size="1" color="c5e1ff">SSLCertificateFile 
                              /etc/ssl/crt/yourdomainname.crt <br>
                              SSLCertificateKeyFile /etc/ssl/crt/private.key<br>
                              SSLCACertificateFile /etc/httpd/conf/ca-bundle/ca_new.txt</font></p>
                          </blockquote>
                          <p><font size="1" color="c5e1ff">Save your virtual host 
                            file and restart Apache. <br>
                            You are now all set to start using your SSL server 
                            certificate with your Apache Ensim configuration.<br>
                            </font></p>
                          <p> <font size="1" color="c5e1ff"><br>
                            </font> </p>
                          <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                          </font> </td>
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
