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
                    <td><img src="../images/installProc.gif" width="288" height="11" vspace="4"><br>
                      <table width="95%" border="0" cellpadding="4" align="center">
                        <tr>

                        <td>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">There
                            are three steps involved in procuring and installing
                            a SSL server certificate, thus enabling SSL to provide
                            security to your site. These steps are: <b>1) generate
                            a CSR</b>, <b>2) enroll for a SSL server certificate</b>,
                            and <b>3) install the SSL server cerificate</b>.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            <b>1) Generate a CSR</b><br>
                            From the web server that will be SSL enabled, generate
                            a CSR (Certificate Signing Request). For detailed
                            CSR generation instructions based on which brand of
                            web server you are using , click the link below:
                            </font></p>
                          <table width="100%" border="0" cellpadding="2">
                            <tr>
                              <td>
                                <div align="center"><span class="hyperlink"><a href="howToGenCSR.jsp"><font face="Verdana, Arial, Helvetica, sans-serif" size="1"><b>CSR
                                  Generation Instructions</b></font></a></span></div>
                              </td>
                            </tr>
                          </table>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br><br>
                            <b>2) Enroll for a SSL server certificate<br>
                            </b>There are several types of SSL server certificate
                            products to choose from by clicking on the &quot;click
                            here to buy&quot; button immediately following this
                            paragraph. These products differ from one another
                            by features and warranty level. You can review the
                            features on the page immediately following the clickable
                            button below. Once the product has been chosen, you
                            will be prompted to submit the CSR that was generated
                            during step <b>1)</b>. Upon enrollment, you will be
                            registered with a mySSL account. This account allows
                            you to track your certificate issuance process, view
                            your order history, and manage multiple certificates.
                            Click the button below now to begin the enrollment
                            process. </font></p>
                          <table width="100%" border="0" cellpadding="2">
                            <tr>
                              <td>
                                <div align="center"><a target="_blank" href="/sglCertificates.jsp">
									<img src="/images/clickToBuy.gif" border=0 width="126" height="19"></a></div>
                              </td>
                            </tr>
                          </table>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br><br>
                            <b>3) Install the SSL server cerificate<br>
                            </b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">
                            Upon receiving your SSL server certificate (either
                            through email or downloaded from your mySSL account),
                            you will need to install your certificate on the web
                            server on which you generated the CSR from step <b>1)</b>.
                            For detailed certificate installation instructions
                            based on which brand of web server you are using ,
                            click the link below: </font></p>
                          <table width="100%" border="0" cellpadding="2">
                            <tr>
                              <td>
                                <div align="center"><span class="hyperlink">
                                  <a href="installation.jsp">
                                    <font face="Verdana, Arial, Helvetica, sans-serif" size="1">
                                      <b>Certificate Installation Instructions</b></font></a></span></div>
                              </td>
                            </tr>
                          </table>
						  <p>&nbsp;</p>
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
