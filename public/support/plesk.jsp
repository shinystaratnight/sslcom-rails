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
                        <td> <font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Generating 
                          a Certificate Signing Request (CSR) using<br>
                          Plesk Server Administrator 2.5 </b></font> 
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Please 
                            note that these files were adapted from online resources 
                            available at <span class="hyperlink"><a href="http://www.plesk.com/html/products/psa/doc.htm">http://www.plesk.com/html/products/psa/doc.htm</a></span></font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">A 
                            CSR is a file containing your certificate application 
                            information, including your Public Key. Generate your 
                            CSR and then copy and paste the CSR file into the 
                            webform in the enrollment process.</font></p>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Important 
                            Notes on Certificates</b></font></p>
                          <ul>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">In 
                              order to use SSL certificates for a given domain, 
                              the domain MUST be set-up for IP-Based hosting. 
                              </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                              an IP-based hosting account is created with SSL 
                              support, a default SSL certificate is uploaded automatically. 
                              However, this certificate will not be recognized 
                              by a browser as one that is signed by a certificate 
                              signing authority. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                              default SSL certificate can be replaced by either 
                              a self-signed certificate or one signed by a recognized 
                              certificate-signing authority. The self-signed certificate 
                              is valid and secure, but many clients prefer to 
                              have a certificate signed by a known Certificate 
                              Signing Authority. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
                              can generate a certificate with the SSLeay utility 
                              and submit it to any valid certificate authority. 
                              This can be done using the CSR option within PSA. 
                              </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">If 
                              the given domain has the www prefix enabled, you 
                              must set-up your CSR or self-signed certificate 
                              with the www prefix included. If you do not, you 
                              will receive a warning message when trying to access 
                              the domain with the www prefix. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Remember 
                              to enter your certificate information in <b>PEM 
                              format</b>. <b>PEM format</b> means that the RSA 
                              Private Key text must be followed by the Certificate 
                              text. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">All 
                              certificates are located in the ../vhosts/'domain 
                              name'/cert/httpsd.pem file. Where this directory 
                              reads &quot;domain name&quot;, you must enter the 
                              domain name for which the certificate was created. 
                              </font></li>
                          </ul>
                          <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Generate 
                            a Self-signed Certificate or Certificate Signing Request</b><br>
                            Access the domain management function by clicking 
                            on the Domains button at the top of the PSA interface. 
                            The Domain List page appears.</font></p>
                          <ol>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              the domain name that you want to work with. The 
                              Domain Administration page appears. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">If 
                              you have established an IP based hosting account 
                              with SSL support, the Certificate button will be 
                              enabled. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              the Certificate button. The SSL certificate setup 
                              page appears. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                              Certificate Information: section lists information 
                              needed for a certificate signing request, or a self-signed 
                              certificate. You must fill out these fields before 
                              generating your CSR or self-signed certificate. 
                              </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                              Bits selection allows you to choose the level of 
                              encryption of your SSL certificate. Select the appropriate 
                              number from the drop down box next to Bits:. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                              enter the information into the provided text input 
                              fields (State or Province, Locality, Organization 
                              Name and Organization Unit Name (optional)) click 
                              in the text boxes and enter the appropriate name. 
                              </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">To 
                              enter the Domain Name for the certificate, click 
                              in the text box next to Domain Name: and enter the 
                              appropriate domain. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
                              domain name is a required field. This will be the 
                              only domain name that can be used to access the 
                              Control Panel without receiving a certificate warning 
                              in the browser. The expected format is www.domainname.com 
                              or domainname.com. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
                              on the Request button. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Selecting 
                              Request results in the sending of a certificate-signing 
                              request (CSR) to the email address you provided 
                              in the certificate fields discussed above. When 
                              a CSR (certificate signing request) is generated 
                              there are two different text sections, the RSA Private 
                              Key and the Certificate Request. Do not lose your 
                              RSA private key. You will need this during the certificate 
                              installation process. Losing it is likely to result 
                              in the need to purchase another certificate. </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Copy 
                              and paste the Certificate Request emailed to you 
                              into the InstantSSL web form where it requests a 
                              CSR (Certificate Signing Request). </font></li>
                            <li><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">When 
                              you are satisfied that the SSL certificate has been 
                              generated or the SSL certificate request has been 
                              correctly implemented, click Up Level to return 
                              to the Domain Administration page. <br>
                              <br>
                              </font> </li>
                          </ol>
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
