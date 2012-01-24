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
                        <td> <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Installing 
                          your Certificate on Microsoft IIS 4.x</b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Step 
                            1. Install the Server file certificate using Key Manager</b> 
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Go 
                            to Key Manager. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Install 
                            the new Server certificate by clicking on the key 
                            in the www directory (usually a broken key icon with 
                            a line through it), and select &quot;Install Key Certificate&quot;. 
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                            the Password. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                            you are prompted for bindings, add the IP and Port 
                            Number. &quot;Any assigned&quot; is acceptable if 
                            you do not have any other certificates installed on 
                            the web server. <br>
                            Note: Multiple certificates installed on the same 
                            web server will require a separate IP Address for 
                            each because SSL does not support host headers. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Go 
                            to the Computers menu and select the option &quot;Commit 
                            Changes&quot;, or close Key Manager and select &quot;Yes&quot; 
                            when prompted to commit changes. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                            new Server certificate is now successfully installed. 
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Back 
                            up the Key in Key Manager by clicking on Key menu&gt; 
                            Export -&gt; Backup File. Store the backup file on 
                            the hard drive AND off the server. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            <b>Step 2: Installing the Root &amp; Intermediate 
                            Certificates:</b></font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Your 
                            Certificate will have been emailed to you. The email 
                            will also contain two other Certificates: GTECyberTrustGlobalRootCA.crt 
                            and ComodoClass3SecurityServicesCA.crt - save these 
                            Certificates to the desktop of the webserver machine.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">It 
                            is essential that you have installed these two Certificates 
                            on the machine running IIS4. You may also download 
                            them below:</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&gt; 
                            <span class="hyperlink"><a href="/support/cacerts/GTECyberTrustRootCA.crt">GTECyberTrustRootCA</a><br>
                            &gt; <a href="/support/cacerts/ComodoSecurityServicesCA.crt">ComodoClass3SecurityServicesCA</a></span> 
                            </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Once 
                            you have installed the Certificates, restart the machine 
                            running IIS4. You must now complete one of the following 
                            procedures - the procedure you follow is dependent 
                            on the Service Pack that has been implemented on your 
                            machine running IIS4.</font></p>
                          <blockquote> 
                            <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b><i>ServicePack 
                              3:</i></b><br>
                              Install the above certificates in your Internet 
                              Explorer by opening each certificate and clicking 
                              &quot;Install Certificate&quot;. You may then use 
                              this <span class="hyperlink"><a href="/support/install/root2iis.bat">IISCA</a></span> 
                              batch file to transfer all root certificates from 
                              your Internet Explorer to the IIS (see <span class="hyperlink"><a href="http://support.microsoft.com/support/kb/articles/q216/3/39.asp">Microsoft 
                              KnowledgeBase Q216339</a></span>).</font></p>
                            <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b><i>ServicePack 
                              4: </i></b><br>
                              Install the above certificates manually in a specicfic 
                              root store (you may also want to read (see <span class="hyperlink"><a href="http://support.microsoft.com/support/kb/articles/q194/7/88.asp">Microsoft 
                              KnowledgeBase Q194788</a></span>):</font></p>
                            <ul>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Install 
                                the GTECyberTrustGlobalRootCA.crt certificate 
                                by double clicking on the corresponding file this 
                                will start an installation wizard </font></li>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">select 
                                <b>Place all certificates in the following store</b> 
                                and click <b>browse</b> </font></li>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">select 
                                <b>Show physical stores</b> </font></li>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">select 
                                <b>Trusted Root Certification Authorities</b> 
                                </font></li>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">select 
                                <b>Local Computer</b>, click <b>OK</b> </font></li>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">back 
                                in the wizard, click <b>Next</b>, click <b>Finish</b> 
                                </font></li>
                              <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Repeat 
                                the same for the ComodoClass3SecurityServicesCA.crt, 
                                however choose to place the certificates in the 
                                <b>Intermediate Certification Authorities</b> 
                                store.</font></li>
                            </ul>
                            <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><i><b>ServicePack 
                              5:</b></i><br>
                              Same as SP4.</font></p>
                            <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><i><b>ServicePack 
                              6:</b></i><br>
                              Same as SP5.</font></p>
                          </blockquote>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Reboot 
                            the web server to complete the installation.<br>
                            </font></p>
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
