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
                        <td> <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Generating 
                          a Certificate Signing Request (CSR) using<br>
                          Java Based Web Servers</b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Use 
                            the keytool command to create the key file:<br>
                            keytool -genkey -keyalg RSA -keystore domain.key -validity 
                            360 (NOTE validity may vary)</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                            following questions will be asked if not known:<br>
                            <br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Enter keystore password: 
                            (NOTE remember this for later use)<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What is your first and 
                            last name? - This is the Common Name (Domain Name)<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What is the name of 
                            your organizational unit?<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What is the name of 
                            your organization?<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What is the name of 
                            your City or Locality?<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What is the name of 
                            your State or Province?<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What is the two-letter 
                            country code for this unit?</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                            will then be asked if the information is correct:<br>
                            Is CN=www.yourdomain.com, OU=Your Oganizational Unit, 
                            O=Your Organization, L=Your City, ST=Your State, C=Your 
                            Country correct?</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                            you answer 'y' or 'yes' the password is then requested:<br>
                            Enter key password for &lt;mykey&gt;<br>
                            NOTE: Make a note of this password<br>
                            &lt;mykey&gt; is the default alias for the certificate</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Use 
                            the keytool command to create the CSR file:<br>
                            keytool -certreq -keyalg RSA -file domain.csr -keystore 
                            domain.key</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                            will be prompted to enter the password.<br>
                            Enter keystore password:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">If 
                            the password is correct then the CSR is created.<br>
                            If the password is incorrect then a password error 
                            is displayed.<br>
                            You will need the text from this CSR when requesting 
                            a certificate.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">For 
                            more details, visit the Java Keytool (or Genkey) support 
                            pages at:</font></p>
						  <span class="hyperlink">
                          <table width="80%" border="0" cellpadding="2">
                            <tr> 
                              <td><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                1.4.1</font></td>
                              <td><a href="http://java.sun.com/j2se/1.4.1/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></td>
                              <td><a href="http://java.sun.com/j2se/1.4.1/docs/tooldocs/windows/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></td>
                            </tr>
                            <tr> 
                              <td><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                1.4</font></td>
                              <td><a href="http://java.sun.com/j2se/1.4/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></td>
                              <td><a href="http://java.sun.com/j2se/1.4/docs/tooldocs/windows/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></td>
                            </tr>
                            <tr> 
                              <td><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                13.</font></td>
                              <td><a href="http://java.sun.com/j2se/1.3/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></td>
                              <td><a href="http://java.sun.com/j2se/1.3/docs/tooldocs/win32/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></td>
                            </tr>
                            <tr> 
                              <td><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">JDK 
                                1.2</font></td>
                              <td><a href="http://java.sun.com/j2se/1.2/docs/tooldocs/solaris/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Solaris 
                                and Linux]</font></a></td>
                              <td><a href="http://java.sun.com/j2se/1.2/docs/tooldocs/win32/keytool.html"><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">[Windows]</font></a></td>
                            </tr>
                          </table>
						  </span>
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
