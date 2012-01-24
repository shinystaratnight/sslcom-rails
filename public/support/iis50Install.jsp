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
                          <p class=p1><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Installing 
                            your Certificate on Microsoft IIS 5.x / 6.x</b></font></p>
                          <p class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><span class=p3>1. 
                            Installing the Root &amp; Intermediate Certificates:</span><br>
                            <br>
                            You will have received 3 Certificates from SSL. Save 
                            these Certificates to the desktop of the webserver 
                            machine, then:</font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              the <b>Start Button</b> then selct <b>Run</b> and 
                              type <i>mmc</i> </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              <b>File</b> and select<b> Add/Remove Snap in</b> 
                              </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
                              <b>Add</b>, select <b>Certificates</b> from the 
                              <b>Add Standalone Snap-in</b> box and click <b>Add</b> 
                              </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
                              <b>Computer Account</b> and click <b>Finish</b> 
                              </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Close 
                              the <b>Add Standalone Snap-in</b> box, click OK 
                              in the Add/Remove Snap in </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Return 
                              to the MMC </font></li>
                          </ul>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                              install the <b>GTECyberTrustRoot </b>Certificate: 
                              </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=384 
      src="../images/support/install/iis50/IISRootInstall2.gif" 
      width=511></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Right 
                              click the <i>Trusted Root Certification Authorities</i>, 
                              select <b>All Tasks</b>, select <b>Import</b>. </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=386 
      src="../images/support/install/iis50/IISRootImport3.gif" 
      width=503></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              <b>Next</b>. </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=386 
      src="../images/support/install/iis50/IISRootImport4.gif" 
      width=503></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Locate 
                              the <b>GTECyberTrustRoot</b> Certificate and click 
                              <b>Next</b>. </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                              the wizard is completed, click <b>Finish</b>. </font></li>
                          </ul>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                              install the <b>ComodoSecurityServicesCA Certificate</b>: 
                              </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=385 
      src="../images/support/install/iis50/IISIntInstall1.gif" 
      width=513></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Right 
                              click the <i>Intermediate Certification Authorities</i>, 
                              select <b>All Tasks</b>, select <b>Import</b>. </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Complete 
                              the import wizard again, but this time locating 
                              the <b>ComodoSecurityServicesCA Certificate</b> 
                              when prompted for the Certificate file. </font></li>
                          </ul>
                          <ul>
                            <li class=p8><font color="c5e1ff" face="Verdana, Arial, Helvetica, sans-serif" size="1">Ensure 
                              that the <b>GTECyberTrustRoot</b> certificate appears 
                              under <b>Trusted Root Certification Authorities</b></font> 
                            <li class=p8><font color="c5e1ff" face="Verdana, Arial, Helvetica, sans-serif" size="1">Ensure 
                              that the <b>ComodoSecurityServicesCA</b> appears 
                              under <b>Intermediate Certification Authorities</b></font> 
                            </li>
                          </ul>
                          <p class=p3><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Installing 
                            your SSL Certificate:</font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
                              <b>Administrative Tools</b> </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Start 
                              <b>Internet Services Manager</b> </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=368 
      src="../images/support/install/iis50/IIS1.gif" 
      width=532></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Open 
                              the properties window for the website. You can do 
                              this by right clicking on the Default Website and 
                              selecting Properties from the menu. </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Open 
                              <b>Directory Security </b>by right clicking on the 
                              Directory Security tab </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=458 
      src="../images/support/install/iis50/IIS2.gif" 
      width=461></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              <b>Server Certificate</b>. The following Wizard 
                              will appear: </font></li>
                          </ul>
                          <p align=center><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><img height=363 
      src="../images/support/install/iis50/IISCertInstall1.gif" 
      width=482></font></p>
                          <ul>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Choose 
                              to <b>Process the Pending Request</b> <b>and</b> 
                              <b>Install the Certificate</b>. Click <b>Next</b>. 
                              </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                              the location of your certificate (you may also browse 
                              to locate your certificate), and then click <b>Next</b>. 
                              </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Read 
                              the summary screen to be sure that you are processing 
                              the correct certificate, and then click <b>Next</b>. 
                              </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                              will see a confirmation screen. When you have read 
                              this information, click <b>Next</b>. </font>
                            <li class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                              now have a server certificate installed. </font></li>
                          </ul>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Important: 
                            You must now restart the computer to complete the 
                            install</b></font></p>
                          <p class=p8><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                            may want to test the Web site to ensure that everything 
                            is working correctly. Be sure to use https:// when 
                            you test connectivity to the site.</font></p>
                          <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                          </font></td>
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
