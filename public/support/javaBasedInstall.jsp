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
                          Certificate on Java Based Web Servers </b></font> 
                          <p><font size="1" color="c5e1ff">The certificates you 
                            receive will be:<br>
                            <i>GTECyberTrustRoot.crt<br>
                            ComodoSecurityServicesCA.crt<br>
                            yourdomain.crt</i></font></p>
                          <p><font size="1" color="c5e1ff">These must be imported 
                            in the correct order:<br>
                            GTECyberTrustRoot.crt<br>
                            ComodoSecurityServicesCA.crt<br>
                            yourdomain.crt</font></p>
                          <p><font size="1" color="c5e1ff">Use the keytool command 
                            to import the certificates as follows:<br>
                            <b>keytool -import -trustcacerts -alias root -file 
                            GTECyberTrustRoot.crt </b></font></p>
                          <p><font size="1" color="c5e1ff">If you are using an 
                            alias then please include the alias command in the 
                            string. Example: </font></p>
                          <p><font size="1" color="c5e1ff"><b>keytool -import 
                            -trustcacerts -alias yyy (where yyy is the alias specified 
                            during CSR creation) -file domain.crt </b></font></p>
                          <p><font size="1" color="c5e1ff">The password is then 
                            requested.<br>
                            Enter keystore password: (This is the one used during 
                            CSR creation)<br>
                            The following information will be displayed about 
                            the certificate and you will be asked if you want 
                            to trust it (the default is no so type 'y' or 'yes'):<br>
                            Owner: CN=GTE CyberTrust Root, O=GTE Corporation, 
                            C=US<br>
                            Issuer: CN=GTE CyberTrust Root, O=GTE Corporation, 
                            C=US<br>
                            Serial number: 1a3<br>
                            Valid from: Fri Feb 23 23:01:00 GMT 1996 until: Thu 
                            Feb 23 23:59:00 GMT 2006<br>
                            Certificate fingerprints:<br>
                            MD5: C4:D7:F0:B2:A3:C5:7D:61:67:F0:04:CD:43:D3:BA:58<br>
                            SHA1: 90:DE:DE:9E:4C:4E:9F:6F:D8:86:17:57:9D:D3:91:BC:65:A6:89:64<br>
                            Trust this certificate? [no]: </font></p>
                          <p><font size="1" color="c5e1ff">Then an information 
                            message will display as follows:<br>
                            Certificate was added to keystore</font></p>
                          <p><font size="1" color="c5e1ff">Use the same process 
                            for the Comodo certificate using the keytool command:<br>
                            <b>keytool -import -trustcacerts -alias comodo -file 
                            ComodoSecurityServicesCA.crt<br>
                            </b> </font></p>
                          <p></p>
                          <p><font size="1" color="c5e1ff">All the certificate 
                            are now loaded and the correct root certificate will 
                            be presented.<br>
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">For 
                            more details, visit the Java Keytool (or Genkey) support 
                            pages at:</font></p>
                          <table width="80%" border="0" cellpadding="2">
                            <tr> 
                              <td><span class="hyperlink"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                1.4.1</font></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.4.1/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.4.1/docs/tooldocs/windows/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></span></td>
                            </tr>
                            <tr> 
                              <td><span class="hyperlink"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                1.4</font></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.4/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.4/docs/tooldocs/windows/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></span></td>
                            </tr>
                            <tr> 
                              <td><span class="hyperlink"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                13.</font></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.3/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.3/docs/tooldocs/win32/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></span></td>
                            </tr>
                            <tr> 
                              <td><span class="hyperlink"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                1.2</font></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.2/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></span></td>
                              <td><span class="hyperlink"><a href="http://java.sun.com/j2se/1.2/docs/tooldocs/win32/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></span></td>
                            </tr>
                          </table>
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
