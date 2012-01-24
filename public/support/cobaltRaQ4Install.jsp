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
                        <td> 
                          <p><font size="1" color="c5e1ff"><b>Installing your 
                            Certificate on a Cobalt RaQ4/XTR </b><br>
                            </font></p>
                          <p><font size="1" color="c5e1ff">Installing the site 
                            certificate </font> </p>
                          <ul>
                            <li><font size="1" color="c5e1ff">Go to the <b>Server 
                              Management</b> screen.</font></li>
                            <li><font size="1" color="c5e1ff">Click the green 
                              icon (Wrench for RaQ4, Pencil for XTR) next to the 
                              SSL enabled virtual site</font></li>
                            <li><font size="1" color="c5e1ff">Click<b> SSL Settings</b> 
                              on the left side. </font></li>
                            <li><font size="1" color="c5e1ff">Copy the entire 
                              contents of the site certificate that you received, 
                              including<br>
                              -----BEGIN CERTIFICATE-----<br>
                              and <br>
                              -----END CERTIFICATE-----</font></li>
                            <li><font size="1" color="c5e1ff">Paste the new certificate 
                              information that you copied into the &quot;Certificate&quot; 
                              window.</font></li>
                            <li><font size="1" color="c5e1ff">Select <b>Use manually 
                              entered certificate</b> from the pull-down menu 
                              at the bottom.</font></li>
                            <li><font size="1" color="c5e1ff">Click <b>Save Changes</b>.</font></li>
                          </ul>
                          <p><img src="/images/support/install/Cobalt/CobaltRaQ2.gif" width="540" height="333"></p>
                          <p></p>
                          <p><font size="1" color="c5e1ff">Install the Intermediate 
                            Certificates</font></p>
                          <p><font size="1" color="c5e1ff">You will need to install 
                            the Intermediate and Root certificates in order for 
                            browsers to trust your certificate. As well as your 
                            site certificate (yourdomainname.crt) two other certificates, 
                            named GTECyberTrustRootCA.crt and ComodoSecurityServicesCA.crt, 
                            are also attached to the email from SSL. Cobalt users 
                            will not require these certificates. Instead you can 
                            install the intermediate certificates using a 'bundle' 
                            method.</font></p>
                          <p><font size="1" color="c5e1ff"><span class="hyperlink"><a href="/support/cacerts/ca_new.txt">Download 
                            a Bundled cert file</a></span></font></p>
                          <p><font size="1" color="c5e1ff">The following will 
                            require that you access the httpd config file. This 
                            may be achieved by telnetting into your webserver.<br>
                            In the Global SSL settings, in the httpd.conf file, 
                            you will need to add the following SSL directive. 
                            <br>
                            This may be achieved by:<br>
                            Copying the bundle file to the same directory as httpd.conf.<br>
                            Add the following line to httpd.conf, if the line 
                            already exists amend it to read the following:</font></p>
                          <blockquote>
                            <p><font size="1" color="c5e1ff"><b>SSLCACertificateFile 
                              /etc/httpd/conf/ca-bundle/ca_new.txt</b></font></p>
                          </blockquote>
                          <p><font size="1" color="c5e1ff">Note: If you are using 
                            a different location and certificate file names you 
                            will need to change the path and filename to reflect 
                            your server.</font></p>
                          <p><font size="1" color="c5e1ff">Cobalt User Guide available 
                            at:<br>
                            <span class="hyperlink"><a href="http://www.sun.com/hardware/serverappliances/documentation/manuals.html" target="_blank">http://www.sun.com/hardware/serverappliances/documentation/manuals.html</a></span> 
                            </font></p>
                          <p><br>
                            <br>
                          </p>
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
