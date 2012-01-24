<%@page language="java" %>
<html>
<head>
<title>SSL Resources - Find Support, FAQ's, and Other Information Here</title>
<meta http-equiv=Content-Type content="text/html; charset=iso-8859-1">
<link href="/styles/global_style.css" type=text/css rel=stylesheet>
</head>
<body text=#c5e1ff vlink=#003366 alink=#333333 link=#012f8b bgcolor=#0b439e
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
                        <td> <font face="Verdana, Arial, Helvetica, sans-serif" size="1"><b>Generating 
                          a Certificate Signing Request (CSR) using<br>
                          Website Pro 3.x </b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1">A 
                            CSR is a file containing your certificate application 
                            information, including your Public Key. Generate your 
                            CSR and then copy and paste the CSR file into the 
                            webform in the enrollment process.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1"><b>Generate 
                            keys and Certificate Signing Request:</b></font></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1">Open 
                              Website Server Properties and select Key Ring </font></li>
                          </ul>
                          <p><img src="/images/support/genCSR/websitePro/websitepro1.gif" width="506" height="519"></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1">Select 
                              New Key Pair and follow the wizard: </font></li>
                          </ul>
                          <p><img src="/images/support/genCSR/websitePro/websitepro2.gif" width="441" height="332"></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1">Ensure 
                              all the details you enter are correct. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1">When 
                              you have completed the wizard select Done, do not 
                              select the box to choose a Certification Authority. 
                              </font></li>
                          </ul>
                          <p><img src="/images/support/genCSR/websitePro/websitepro7.gif" width="441" height="332"></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1">When 
                              enrolling for a Certificate locate the CSR file 
                              and copy/paste the Certificate Request text into 
                              the CSR box. Complete the online enrollment process 
                              <br>
                              </font></li>
                          </ul>
                          <br>
                          <p></p>
                          <br>
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
