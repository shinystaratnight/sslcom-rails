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
                            <p><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1">Instructions
                              for generating a </font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Certificate
                              Signing Request (CSR)</font><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1">
                              are dependant on the webserver software you are
                              using. Just select the webserver software you are
                              using from the list on the right after reading the
                              Important Information below. </font></p>
                            <p><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1">SSL
                              Server Certificates are compatible with all secure
                              webserver software. If the webserver software you
                              are using is not listed, please contact <span class="hyperlink"><a href="mailto:support@ssl.com">support@ssl.com</a></span>
                              with complete details of your webserver software
                              (please be sure to included the vendor name, software
                              title and version of the software).</font></p>
                            <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b><font color="ff0000">Important
                              Information:<br>
                              <br>
                              </font></b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="ff0000"><b><font color="c5e1ff">Understanding
                              the Common Name</font></b> </font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                              Before you can enroll for a SSL Server Certificate,
                              you must generate a CSR from your webserver software.
                              During the creation of the CSR, the following fields
                              must be entered: Organization (O), Organizational
                              Unit (OU), Country (C), State (S), Locality (L),
                              and Common Name (CN). The Common Name field is often
                              misunderstood and is filled out incorrectly. <br>
                              <br>
                              The Common Name is typically composed of Host +
                              Domain Name and will look like "www.yoursite.com"
                              or "yoursite.com". SSL Server Certificates are specific
                              to the Common Name that they have been issued to at the Host
                              level. The Common Name must be the same as the Web
                              address you will be accessing when connecting to
                              a secure site. For example, a SSL Server Certificate for the
                              domain "domain.com" will receive a warning if accessing
                              a site named "www.domain.com" or "secure.domain.com",
                              as "www.domain.com" and "secure.domain.com" are
                              different from "domain.com". You would need to create
                              a CSR for the correct Common Name. When the Certificate
                              will be used on an Intranet (or internal network),
                              the Common Name may be one word, and it can also
                              be the name of the server. </font></p>
                            <p><br>
                              <br>
                            </p>
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
        <!-- /scripts/genCSRServerList.jsp begin -->
        <jsp:include page="/scripts/genCSRServerList.jsp" flush="true"/>
        <!-- /scripts/genCSRServerList.jsp end -->
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
