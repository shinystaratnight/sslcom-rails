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
                        <td> <font size="1" color="c5e1ff"><b>Installing your 
                          Certificate on Zeus </b></font> 
                          <p><font size="1" color="c5e1ff">When you receive your 
                            certificates there will be 3 files, open a text editor 
                            and then copy the text from each certificate into 
                            the text editor to form one file. The certificates 
                            should be pasted in the following sequence, your site 
                            Certificate named yourdomain.crt, ComodoClass3SecurityServicesCA.crt, 
                            GTECyberTrustGlobalRootCA.crt, and the resulting file 
                            should look like the following:</font></p>
                          <p><font size="1" color="c5e1ff">-----BEGIN CERTIFICATE-----<br>
                            (Your Site Certificate Encoded Text)<br>
                            -----END CERTIFICATE-----<br>
                            -----BEGIN CERTIFICATE-----<br>
                            (ComodoClass3SecurityServicesCA Encoded Text)<br>
                            -----END CERTIFICATE-----<br>
                            -----BEGIN CERTIFICATE-----<br>
                            (GTECyberTrustGlobalRootCA Encoded Text)<br>
                            -----END CERTIFICATE-----</font></p>
                          <p><font size="1" color="c5e1ff">Please note: Make sure 
                            you include the -----BEGIN CERTIFICATE----- and -----END 
                            CERTIFICATE----- as displayed above.</font></p>
                          <p><font size="1" color="c5e1ff">1. Login to the web 
                            server.</font></p>
                          <p><font size="1" color="c5e1ff">2. Select SSL certificates</font></p>
                          <p><img src="/images/support/install/zeus/zeus1.gif"></p>
                          <p><font size="1" color="c5e1ff">3. Select Generate 
                            CSR (or Replace Certificate) against the certificate 
                            set</font></p>
                          <p><img src="/images/support/install/zeus/zeus2.gif"></p>
                          <p><font size="1" color="c5e1ff">4. Copy/Paste the text 
                            from the text editor into the Signed Certificate box 
                            and click OK.</font></p>
                          <p><img src="/images/support/install/zeus/zeus6.gif"></p>
                          <p><font size="1" color="c5e1ff">5. Then select Accept 
                            this Certificate</font></p>
                          <p></p>
                          <p><font size="1" color="c5e1ff">6. The certificate 
                            set now needs assigning to the web site. Click on 
                            the Home icon. Put a tick in the box next to the virtual 
                            server to configure and select configure.</font></p>
                          <p><img src="/images/support/install/zeus/zeus7.gif"></p>
                          <p><font size="1" color="c5e1ff">7. Click on SSL Enabled.</font></p>
                          <p><img src="/images/support/install/zeus/zeus8.gif"></p>
                          <p><font size="1" color="c5e1ff">8. Enable SSL and select 
                            the certificate set to use.</font></p>
                          <p><img src="/images/support/install/zeus/zeus9.gif"></p>
                          <p><font size="1" color="c5e1ff">9. Apply and commit 
                            the changes then restart the web server.<br>
                            </font><font size="1"> </font> </p>
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
