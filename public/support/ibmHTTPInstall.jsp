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
                        <td> <font size="1" color="c5e1ff"><b>Installing your 
                          Certificate on a IBM HTTP Server <br>
                          Using IKEYMAN for Certificate Installation </b></font> 
                          <p><font size="1" color="c5e1ff">In addition to the 
                            server certificate SSL sent, an Intermediate CA Certificate 
                            (the Comodo certificate) and a Root CA Certificate 
                            (GTE CyberTrust) was sent also. Before installing 
                            the server certificate, install both of these certificates. 
                            Follow the instructions in 'Storing a CA certificate'. 
                            </font></p>
                          <p><font size="1" color="c5e1ff">Note: If the authority 
                            who issues the certificate is not a trusted CA in 
                            the key database, you must first store the CA certificate 
                            and designate the CA as a trusted CA. Then you can 
                            receive your CA-signed certificate into the database. 
                            You cannot receive a CA-signed certificate from a 
                            CA who is not a trusted CA. For instructions see 'Storing 
                            a CA certificate'.</font></p>
                          <p><font size="1" color="c5e1ff"><b>Storing a CA Certificate:</b></font></p>
                          <ul>
                            <li><font size="1" color="c5e1ff">Enter IKEYMAN on 
                              a command line on UNIX, or start the Key Management 
                              utility in the IBM HTTP Server folder on Windows. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">Select Key Database 
                              File from the main User Interface, select Open. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">In the Open dialog 
                              box, select your key database name. Click OK. </font></li>
                            <li><font size="1" color="c5e1ff">In the Password 
                              Prompt dialog box, enter your password and click 
                              OK. </font></li>
                            <li><font size="1" color="c5e1ff">Select Signer Certificates 
                              in the Key Database content frame, click the Add 
                              button. </font></li>
                            <li><font size="1" color="c5e1ff">In the Add CA Certificate 
                              from a File dialog box, select the certificate to 
                              add or use the Browse option to locate the certificate. 
                              Click OK. </font></li>
                            <li><font size="1" color="c5e1ff">In the Label dialog 
                              box, enter a label name and click OK. </font></li>
                          </ul>
                          <p><font size="1" color="c5e1ff"><b>To receive the CA-signed 
                            certificate into a key database:</b></font></p>
                          <ul>
                            <li><font size="1" color="c5e1ff">Enter IKEYMAN on 
                              a command line on UNIX, or start the Key Management 
                              utility in the IBM HTTP Server folder on Windows. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">Select Key Database 
                              File from the main User Interface, select Open. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">In the Open dialog 
                              box, select your key database name. Click OK. </font></li>
                            <li><font size="1" color="c5e1ff">In the Password 
                              Prompt dialog box, enter your password, click OK. 
                              </font></li>
                            <li><font size="1" color="c5e1ff">Select Personal 
                              Certificates in the Key Database content frame and 
                              then click the Receive button. </font></li>
                            <li><font size="1" color="c5e1ff">In the Receive Certificate 
                              from a File dialog box, select the certificate file. 
                              Click OK.</font></li>
                          </ul>
                          <p><font size="1" color="c5e1ff">Note: IBM has prepared 
                            a special guide called &quot;<span class="hyperlink"><a href="http://www.instantssl.com/support/cert_installation/CertificatesOS390WebServer.pdf">Global 
                            Certificate Usage with OS/390 Webservers.</a></span>&quot;<br>
                            </font></p>
                          <p> <br>
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
