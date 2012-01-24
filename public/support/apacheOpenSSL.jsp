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
                        <td> <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Genenerating 
                          a Certificate Signing Request (CSR) using<br>
                          Apache Mod_SSL </b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">A 
                            CSR is a file containing your certificate application 
                            information, including your Public Key. Generate your 
                            CSR and then copy and paste the CSR file into the 
                            webform in the enrollment process:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Generate 
                            keys and certificate:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                            generate a pair of private key and public Certificate 
                            Signing Request (CSR) for a webserver, &quot;server&quot;, 
                            use the following command :</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;openssl 
                            req &#150;new &#150;nodes -keyout myserver.key &#150;out 
                            server.csr</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">This 
                            creates a two files. The file myserver.key contains 
                            a private key; do not disclose this file to anyone. 
                            Carefully protect the private key.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                            particular, be sure to backup the private key, as 
                            there is no means to recover it should it be lost. 
                            The private key is used as input in the command to 
                            generate a Certificate Signing Request (CSR).</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                            will now be asked to enter details to be entered into 
                            your CSR. <br>
                            What you are about to enter is what is called a Distinguished 
                            Name or a DN. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">For 
                            some fields there will be a default value, If you 
                            enter '.', the field will be left blank. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;----- 
                            <br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Country 
                            Name (2 letter code) [US]: US<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;State or 
                            Province Name (full name) []: Texas<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Locality 
                            Name (eg, city) []: Houston<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Organization 
                            Name (eg, company) []: Your Company Inc<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Organizational 
                            Unit Name (eg, section) []: Your Department<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Common Name 
                            (eg, YOUR name) []: secure.yourcompanyname.com<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Email Address 
                            []:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Please 
                            enter the following 'extra' attributes to be sent 
                            with your certificate request</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A 
                            challenge password []: <br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;An optional 
                            company name []:<br>
                            &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;----- 
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Use 
                            the name of the webserver as Common Name (CN). If 
                            the domain name is mydomain.com append the domain 
                            to the hostname (use the fully qualified domain name).</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                            fields email address, optional company name and challenge 
                            password can be left blank for a webserver certificate.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            Your CSR will now have been created. Open the server.csr 
                            in a text editor and copy and paste the contents into 
                            the online enrollment form when requested.</font></p>
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
