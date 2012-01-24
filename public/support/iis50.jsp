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
                          a Key Pair and CSR for <br>
                          Microsoft IIS 5.0</b> <br>
                          <br>
                          <b>This document introduces generating a Key Pair and
                          CSR, and answers questions you might have. It assumes
                          that there are no existing keys installed in Internet
                          Information Server (IIS).</b> <br>
                          <!--MAIN CONTENT AREA-->
                          <!--BEGIN TABLE OF CONTENTS-->
                          </font>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><span class="hyperlink"><a href="#genServer">Generating 
                              a Key Pair and CSR for a Microsoft Server</a></span><br>
                              </font>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><span class="hyperlink"><a href="#information">Additional
                              Information</a></span></font></li>
                          </ul>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">
                            <!--END TABLE OF CONTENTS-->
                            <a name="steps"> </a> <br>
                            <br>
                            <!--BEGIN TABLE ONE-->
                            <a name="genServer"> </a> <b>Generating a Key Pair
                            and CSR for a Microsoft Server<br>
                            </b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To
                            generate a public and private key pair and CSR for
                            a Microsoft Internet Information Server 5.0: </font>
                          </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Start
                            the Key Generation Process</b><br>
                            Under Administrative Tools, open the Internet Services
                            Manager. Then open up the properties window for the
                            website you wish to request the certificate for.&nbsp;
                            Right-clicking on the particular website will open
                            up its properties.<br>
                            &nbsp;&nbsp;<br>
                            <img border=0 height=316
        src="../images/support/iis50_1.gif" width=364><br>
                            &nbsp; &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Open
                            Directory Security Folder</b><br>
                            In the Directory Security folder click on the "Server
                            Certificate" button in the Secure communications section.
                            If you have not used this option before the "Edit"
                            button will not be active.<br>
                            &nbsp;&nbsp;<br>
                            <img border=0
        height=344 src="../images/support/iis50_2.gif"
        width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Select
                            "Create a new certificate"</b><br>
                            Unless you have a good reason to do otherwise, you
                            should choose to "create a new certificate".<br>
                            &nbsp;&nbsp;<br>
                            <img border=0 height=207
        src="../images/support/iis50_3.jpg" width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Prepare
                            the request</b><br>
                            You'll prepare the request now, but you can only submit
                            the request (CSR) via our online request forms. We
                            don't accept CSR's via email.<br>
                            &nbsp;&nbsp;<br>
                            <img border=0 height=148
        src="../images/support/iis50_4.gif" width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Enter 
                            a certificate name and the certificate strength</b><br>
                            At this point you will decide what encryption strength 
                            your private key and CSR will be set at. It would 
                            be a good idea to choose the highest you are allowed 
                            to go. If you are outside the US you may want to generate 
                            a Server Gated Crypto certificate. Merely choosing 
                            this option will not mean that you'll automatically 
                            get issued with an SGC certificate. You'll still have 
                            to go through our SGC verification process.&nbsp;<br>
                            <br>
                            Note: If you are running&nbsp; a server intensive 
                            application (eg, asp) over SSL, then a larger key 
                            (1024) may result in your server being too slow.&nbsp;<br>
                            &nbsp;&nbsp;<br>
                            <img border=0 height=275
        src="../images/support/iis50_5.gif" width=352><br>
                            <br>
                            You have now created a public/private key pair.&nbsp; 
                            The private key is stored locally on your machine. 
                            The public portion is sent to VeriSign in the form 
                            of a Certificate Signing Request.<br>
                            <br>
                            <a
        name=csr_gen><b>You will now create a Certificate Signing Request (CSR)</b></a></font><br>
                            <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">This 
                            information will be displayed on your certificate, 
                            and identifies the owner of the key to users. The 
                            CSR is only used to request the certificate.</font><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><font color=#ff0000><br>
                            &nbsp;&nbsp;&nbsp; </font> </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Enter
                            your Organization Information</b><br>
                            You should enter in these fields what appears on your
                            official company registration documents.&nbsp;</font>
                            <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            &nbsp;&nbsp;<br>
                            <img
        border=0 height=276 src="../images/support/iis50_6.gif" width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Enter
                            your common name</b><br>
                            The term "common name" is X.509 speak for the name
                            that distinguishes the certificate best, and ties
                            it to your web site. In the case of SSL web server
                            certificates, <b>enter the host plus domain name (i.e.
                            secure.verisign.com)</b> .&nbsp;<br>
                            &nbsp;&nbsp;<br>
                            <img border=0 height=276
        src="../images/support/iis50_7.gif" width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Enter
                            the geographical details</b><br>
                            Your country, state or province and locality or city.<br>
                            &nbsp;&nbsp;<br>
                            <img border=0
        height=275 src="../images/support/iis50_8.gif" width=352><br>
                            &nbsp; </font> <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                            &nbsp;&nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Choose
                            a filename to save the request to</b><br>
                            Select an easy to locate folder. You'll have to open
                            this file up with Notepad. The CSR must be copied
                            and pasted into our online form. Once the CSR has
                            been submitted, you won't need this CSR.&nbsp;<br>
                            &nbsp;&nbsp;<br>
                            <img
        border=0 height=274 src="../images/support/iis50_10.gif" width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Confirm
                            your request details</b><br>
                            &nbsp;&nbsp;<br>
                            <img border=0
        height=276 src="../images/support/iis50_11.gif" width=352><br>
                            &nbsp; </font> </p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Finish
                            up and exit IIS Certificate Wizard</b><br>
                            &nbsp;&nbsp;<br>
                            <img border=0 height=275
        src="../images/support/iis50_12.gif" width=352><br>
                            <br>
                            </font></p>
                          <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">&nbsp;&nbsp;<span class="hyperlink"><a href="#top">return
                          to the top</a></span>
                          <!--END TABLE ONE-->
                          <!--END TABLE TWO-->
                          <br>
                          <br>
                          <!--BEGIN TABLE THREE-->
                          <a name="information"> </a> <b>Additional Information</b>
                          <br>
                          For more information, refer to your server documentation
                          or visit <span class="hyperlink"><a href="http://support.microsoft.com/support/">Microsoft
                          Support Online</a></span>. <br>
                          &nbsp;&nbsp;<span class="hyperlink"><a href="#top">return
                          to the top</a></span><br>
                   
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
