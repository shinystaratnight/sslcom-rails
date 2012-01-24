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
                          Stronghold Server </b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Note: 
                            Keys and certificates are managed through three scripts: 
                            genkey, getca and genreq. These are part of the normal 
                            Stronghold distribution. Keys and certificates are 
                            stored in the directory$SSLTOP/private/, where SSLTOP 
                            is typically /usr/local/ssl. </font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                            generate a key pair and CSR for your server: </font></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Run 
                              genkey, specifying the name of the host or virtual 
                              host: genkey hostname. The genkey script displays 
                              the filenames and locations of the key file and 
                              CSR file it will generate: <br>
                              Key file: /usr/local/www/sslhostname.key <br>
                              CSR file: /usr/local/www/sslhostname.cert </font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                              </font></li>
                          </ul>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Note: 
                            If you already have a key for your server, run genreq 
                            [servername] to generate only the CSR. </font></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Press 
                              Enter. The genkey script reminds you to be sure 
                              you are not overwriting an existing key pair and 
                              certificate.</font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                              prompted, enter a key size in bits. It is recommended 
                              that you use the largest key size available: 1024 
                              or 512.</font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                              prompted, enter random key strokes. Stop when the 
                              counter reaches zero and genkey beeps. This random 
                              data is used to create a unique public and private 
                              key pair. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                              prompted, enter 'y' to create the key pair and CSR. 
                              <br>
                              For your CA select 'Other'. </font> 
                              <ul>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                                  the two-letter country code for your country. 
                                  You must use the correct ISO country code, other 
                                  abbreviations will not be recognized. To find 
                                  your country code, <span class="hyperlink"><a href="countryCodes.jsp">click 
                                  here</a></span>. </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                                  the full name of your state or province. Do 
                                  not abbreviate. </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                                  the name of your city, town, or other locality. 
                                  </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                                  the name of your organization. </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                                  the name of your unit within the specified organization. 
                                  </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                                  your web site's fully-qualified name. For example 
                                  www.company.com. This is also known as your 
                                  site's common name. </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                                  you have finished entering the CSR data, genkey 
                                  automatically creates the CSR. </font></li>
                              </ul>
                              <blockquote> 
                                <p>&nbsp;</p>
                              </blockquote>
                            </li>
                          </ul>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Back 
                            up your key file and CSR on a floppy disk and store 
                            the disk in a secure location. If you lose your private 
                            key or forget the password, you will not be able to 
                            install your certificate.<br>
                            </font></p>
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
