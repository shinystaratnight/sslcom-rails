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
                          IBM HTTP Server (via IKEYMAN </b>for <b>CSR Generation</b><b>)</b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Note: 
                            If you are starting IKEYMAN to create a new key database 
                            file, the file is stored in the directory where you 
                            start IKEYMAN.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>To 
                            create a new Key Database: </b></font></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">A 
                              key database is a file that the server uses to store 
                              one or more key pairs and certificates. You can 
                              use one key database for all your key pairs and 
                              certificates, or create multiple databases. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                              IKEYMAN on a command line on UNIX, or start the 
                              Key Management utility in the IBM HTTP Server folder, 
                              on Windows.</font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
                              Key Database File from the main user interface, 
                              select New. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              the New dialog box, enter your key database name. 
                              Click OK.</font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              the Password Prompt dialog box, enter a password, 
                              enter to confirm the password. Click OK. </font></li>
                          </ul>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            <b>Creating a New Key Pair and Certificate Request:</b></font></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Enter 
                              IKEYMAN on a command line on UNIX, or start the 
                              Key Management utility in the IBM HTTP Server folder 
                              on Windows. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
                              Key Database File, from the main user interface 
                              and select Open. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              the Open dialog box, select your key database name. 
                              Click OK. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              the Password Prompt dialog box, enter your correct 
                              password and click OK. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
                              Create from the main user interface, select New 
                              Certificate Request. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              the New Key and Certificate Request dialog box, 
                              enter: </font> 
                              <ul>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Key 
                                  Label: A descriptive comment to identify the 
                                  key and certificate in the database. </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Keysize: 
                                  </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Organization 
                                  Name: </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Organization 
                                  Unit: </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Locality: 
                                  </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">State/Province: 
                                  </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Zipcode/Postcode:# 
                                  </font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Country: 
                                  Enter a country code. Example: US or GB. Click 
                                  <span class="hyperlink"><a href="countryCodes.jsp">here</a></span> to find 
                                  your country code</font></li>
                                <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Certificate 
                                  request file name, or use the default name </font></li>
                              </ul>
                            </li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              OK. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              the Information dialog box, click OK. </font></li>
                          </ul>
                          <p></p>
                          <p><br>
                          </p>
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
