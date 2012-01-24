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
                    <td><img src="../images/howToGenCSR.gif" width="158" height="11" vspace="4"><br>

                    <table width="95%" border="0" cellpadding="4" align="center">
                      <tr>
                        <td>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Installing
                            your Certificate</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The
                            final part of your SSL Server Certificate application
                            is the installation of your certificate. Installation
                            of your SSL Server Certificate will differ greatly
                            dependent on your webserver software. Select your
                            webserver software from the list after reading the
                            following general points: </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">General
                            Points to remember:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When
                            you are emailed your SSL Server Certificate, two other
                            certificates will also be attached to the email. Should
                            they be required, you may download these certificates
                            individually or collectively as a bundled file below:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"> 
                            <a href="http://info.ssl.com/ssl_kb/article.aspx?id=10019" target="_blank"><img src="../images/support/cert.gif" width="17" height="13" align="absmiddle" border="0"></a><span class="hyperlink"><a href="http://info.ssl.com/ssl_kb/article.aspx?id=10019" target="_blank">GTE 
                            CyberTrust Root CA</a></span><br>
                            <br>
                            <a href="http://info.ssl.com/ssl_kb/article.aspx?id=10019" target="_blank"><img src="../images/support/cert.gif" width="17" height="13" align="absmiddle" border="0"></a><span class="hyperlink"><a href="http://info.ssl.com/ssl_kb/article.aspx?id=10019" target="_blank">Comodo 
                            Class 3 Security Services CA</a></span></font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"> 
                            <span class="hyperlink"><a href="http://info.ssl.com/ssl_kb/article.aspx?id=10019" target="_blank">Bundled 
                            cert file</a></span><br>
                            (needed for Apache and Plesk Administrator installations)</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            Hosting companies:<br>
                            If you need to install more than one CA bundle file 
                            (roots) on an Apache set up, click <span class="hyperlink"><a href="http://info.ssl.com/ssl_kb/article.aspx?id=10019">here</a></span> 
                            for instructions.</font></p>
                          <p><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1">SSL
                            Server Certificates are compatible with all secure
                            webserver software. If the webserver software you
                            are using is not listed, please contact <span class="hyperlink"><a href="mailto:support@ssl.com">support@ssl.com</a></span>
                            with complete details of your webserver software (please
                            be sure to included the vendor name, software title
                            and version of the software).</font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            <br>
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
