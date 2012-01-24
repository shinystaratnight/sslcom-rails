<%@page language="java" %>
<html>
<head>
<title>SSL Support - How To Generate a Certificate Signing Request(CSR)</title>
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
        <td align=middle colspan=10>&nbsp;</td>
      </tr>
      <tr>
        <td class=footerLine colspan=10 height=1><img height=1 alt=""
      src="../images/shim.gif" width=1 border=0></td>
      </tr>
      <tr>
        <td width=13><img height=1 alt="" src="../images/shim.gif"
      width=27 border=0></td>
        <td width=19% valign="top"> <img src="../images/ResourcesH2.gif" width="76" height="11" vspace="22"><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1"><b><br>
          &nbsp;&raquo; CSR Gen &laquo;<br>
          <br>
          &nbsp;&raquo; Required docs<br>
          <br>
          &nbsp;<br>
          </b></font> </td>
        <td class=footerLine width=1><img height=109 alt=""
      src="../images/shim.gif" width=1 border=0></td>
        <td width=18><img height=8 alt="" src="../images/shim.gif"
      width=18 border=0></td>
        <td width=60% valign=top>
          <table bgcolor=#012f8b width="100%" border="0">
            <tr>
              <td width="100%"><img src="../images/supportH1.gif" width="110" height="26" vspace="11"></td>
            </tr>
            <tr>
              <td align="center">
                <table width="95%" border="0" cellpadding="0" align="right">
                  <tr>
                    <td><img src="../images/howToGenCSR.gif" width="158" height="11" vspace="4"><br>
                      <table width="95%" border="0" cellpadding="4" align="center">
                        <tr>
                          <td>

                            <table border=0 width="100%" cellpadding=0 cellspacing=0>
                              <tr>
                                <td width="70%" valign="top">
                                  <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
                                    <b> Error-Free CSR Generation: Important Information
                                    </b> </font> </p>
                                  <p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><b>Understanding
                                    the Common Name</b> <br>
                                    Before you can enroll for a VeriSign Server
                                    ID, you must generate a Certificate Signing
                                    Request (CSR) from your Web server. During
                                    the creation of the CSR, the following fields
                                    are to be entered: Organization, Organizational
                                    Unit, Country, State, Locality, and Common
                                    Name. The Common Name field is often misinterpreted
                                    and is filled out incorrectly. <br>
                                    <br>
                                    The Common Name is typically composed of Host
                                    + Domain Name and will look like "www.company.com"
                                    or "company.com". VeriSign Server IDs are
                                    specific to the Common Name that they have
                                    been issued to at the Host level. The Common
                                    Name must be the same as the Web address you
                                    will be accessing when connecting to a secure
                                    site. For example, a Server ID for the domain
                                    "domain.com" will receive a warning if accessing
                                    a site named "www.domain.com" or "secure.domain.com",
                                    as "www.domain.com" and "secure.domain.com"
                                    are different from "domain.com". You would
                                    need to create a CSR for the correct Common
                                    Name. When the Server ID will be used on an
                                    Intranet (or internal network), the Common
                                    Name may be one word, and it can also be the
                                    name of the server. </font> </p>
                                </td>
                              </tr>
                            </table>
                            </td>
                        </tr>
                        <tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>
        </td>
        <td class=footerLine width=1><img height=109 alt=""
      src="../images/shim.gif" width=1 border=0></td>
        <td width=18><img height=8 alt="" src="../images/shim.gif"
      width=18 border=0></td>
        <td valign=top>
          <table border="0" >
            <tr>
              <td align="center"> <img src="../images/getSSL.gif" width="124" height="96" vspace="15"><br>
            </tr>
            <tr>
              <td>
                <p><b><font face="Verdana,Geneva,Helvetica,Arial" color="#c5e1ff" size="1">
                  &#149; 128-bit high grade encryption</font><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff"><br>
                  <br>
                  &#149; validation assured</font><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff"><br>
                  <br>
                  &#149; competitive pricing</font><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff"><br>
                  <br>
                  &#149; backed by $10,000 warranty<br>
                  <br>
                  &#149; compatible with 99% of browsers<br>
                  <br>
                  &#149; quick issuance<br>
                  <br>
                  &#149; telephone, email, and web support</font></b></p>
                <p align="center"><b><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff">&#151;<br>
                  </font></b><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff"><br>
                  </font></p>
            </tr>
            <tr>
              <td align="left"><b><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff">1
                YEAR - $249.00</font></b><br>
                <br>
                <b><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff">2
                YEARS - $499.00</font></b><br>
                <br>
                <b><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff">3
                YEARS - $619.00</font></b><br>
                <br>
                <b><font face="Verdana,Geneva,Helvetica,Arial" size="1" color="#c5e1ff">BULK
                BUY - $reduced</font></b><br>
                <br>
                <img src="../images/clickToBuy.gif" width="126" height="19"> </td>
            </tr>
          </table>
        </td>
        <td width=27><img height=1 alt="" src="../images/shim.gif"
      width=27 border=0></td>
      </tr>
      <tr>
        <td class=footerLine colspan=10 height=1><img height=1 alt=""
      src="../images/shim.gif" width=1 border=0></td>
      </tr>
      <tr>
        <td align=middle colspan=10>&nbsp;</td>
      </tr>
      <tr>
        <td class=footerDark align=middle colspan=10><img height=11
      alt="universally accepted | telephone, email, and web customer support | best discounted pricing"
      hspace=0 src="../images/footerBar.gif" width=596 vspace=12
      border=0></td>
      </tr>
      <tr>
        <td align=middle colspan=10><img src="../images/partnering.gif" width="334" height="11"><img src="../images/info.gif" width="52" height="18" align="absmiddle" hspace="2" vspace="4"></td>
      </tr>
      <tr>
        <td class=footerLine colspan=10 height=1><img height=1 alt=""
      src="../images/shim.gif" width=1 border=0></td>
      </tr>
      <tr>
        <td align=middle colspan=10>
          <div class=footerSm
      style="PADDING-RIGHT: 15px; PADDING-LEFT: 15px; PADDING-BOTTOM: 15px; PADDING-TOP: 15px">Copyright
            &copy; 2002 SSL. All rights reserved.</div>
          <div style="PADDING-BOTTOM: 50px; PADDING-TOP: 5px"><img
      alt=SSL hspace=0 src="../images/sslLockSign.gif"
      border=0 width="31" height="32"></div>
        </td>
      </tr>
      </tbody>
    </table>
    <!-- /components/footernav.jsp end -->
  </center>
</div>
</body>
</html>
