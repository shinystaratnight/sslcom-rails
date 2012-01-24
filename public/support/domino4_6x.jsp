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
                        <td> <font size="1"><b>Generating a Certificate Signing 
                          Request (CSR) using<br>
                          Lotus Domino Server versions 4.6x</b></font> 
                          <ul>
                            <li><font size="1">From the administration panel, 
                              click <b>System Databases</b> and choose <b>Open 
                              Domino Server Certificate Administration (CERTSRV.NSF)</b> 
                              on the local machine. Click <b>Create Key Ring</b>. 
                              </font></li>
                            <li><font size="1">Enter a name for the key ring file 
                              in the<b> &quot;Key Ring File Name&quot;</b> field. 
                              </font></li>
                            <li><font size="1">Enter a password for the server 
                              key ring file in the <b>&quot;Key Ring Password&quot;</b> 
                              field. <br>
                              Note: The password is case sensitive. </font></li>
                            <li><font size="1">Select a key size. This is the 
                              size Domino uses when creating the public and private 
                              key pairs. <br>
                              Note: If you are using the international version 
                              of Domino, only the 512 bit key size will work for 
                              you unless you have Release R5.04. </font></li>
                            <li><font size="1">Specify the components of your 
                              server's distinguished name. </font></li>
                            <li><font size="1">Click <b>Create Key Ring</b>. Click 
                              <b>OK</b>. </font></li>
                            <li><font size="1">Click <b>Create Certificate Request</b>. 
                              </font></li>
                          </ul>
                          <p><font size="1">Note: You must select all the text 
                            in the second dialog box, including <b>Begin Certificate</b> 
                            and <b>End Certificate</b> when the <b>CSR</b> is 
                            requested.</font></p>
                          <p></p>
                          <font size="1"><br>
                          <font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"><br>
                          </font></font> </td>
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
