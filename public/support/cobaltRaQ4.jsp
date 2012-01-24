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
                          Cobalt RaQ4/XTR </b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>To 
                            enable SSL on a virtual site:</b><br>
                            Go to the Server Management screen.<br>
                            Click the green icon (Wrench for RaQ4, Pencil for 
                            XTR) next to the virtual site on which you want to 
                            enable SSL. The Site Management screen appears.<br>
                            Click Site Settings on the left side.<br>
                            (Then 'General' for XTR)<br>
                            Click the check box next to Enable SSL.<br>
                            Click Save Changes.<br>
                            The RaQ4/XTR saves the configuration of the virtual 
                            site.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Generate 
                            a self-signed certificate:</b><br>
                            Once SSL is enabled, the user must now create a self-signed 
                            certi?cate. The self-signed certi?cate will be signed 
                            later by an external authority.<br>
                            Go to the Server Management screen.<br>
                            Click the green icon (Wrench for RaQ4, Pencil for 
                            XTR) next to the SSL enabled virtual site<br>
                            Click SSL Settings on the left side. <br>
                            The Certificate Subject Information table appears.<br>
                            Enter the following information:<br>
                            &nbsp;&nbsp;&nbsp;Country (enter the two-letter country 
                            code)<br>
                            &nbsp;&nbsp;&nbsp;State (enter the name of the state 
                            or county)<br>
                            &nbsp; &nbsp;Locality (enter the city or locality)<br>
                            &nbsp;&nbsp;&nbsp;Organization (enter the name of 
                            the organization)<br>
                            &nbsp;&nbsp;&nbsp;Organizational Unit (optional)( 
                            enter the name of a department)<br>
                            Select Generate self-signed certificate from the pull-down 
                            menu at the bottom.<br>
                            Click Save Changes. <br>
                            The RaQ4/XTR processes the information and regenerates 
                            the screen with the new self-signed certificate in 
                            the Certificate Request and Certificate windows.</font></p>
                          <p><img src="/images/support/genCSR/Cobalt/CobaltRaQ1.gif"></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Copy 
                            the entire contents of the certificate request, including<br>
                            -----BEGIN CERTIFICATE REQUEST-----<br>
                            and<br>
                            -----END CERTIFICATE REQUEST-----<br>
                            for use during the purchasing process.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Cobalt 
                            User Guide available at:<br><span class="hyperlink">
                            <a href="http://www.sun.com/hardware/serverappliances/documentation/manuals.html">http://www.sun.com/hardware/serverappliances/documentation/manuals.html</a></span> 
                            </font></p>
                          <p> </p>
                          <p> </p>
                          <p> <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            </font> </p>
                        </td>
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
