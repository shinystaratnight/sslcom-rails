
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"> 

<html>
<head>
<title>Microsoft Internet Information Server 5</title>
<link href="/styles/global_style.css" type=text/css rel=stylesheet>
</head>
<body text=black vlink=#003366 alink=#333333 link=#012f8b bgcolor=#0b439e
topmargin=0>
<h1><font face="Verdana, Arial, Helvetica, sans-serif" size="4" color="c5e1ff">Microsoft 
  Internet Information Server 5</font></h1>
<h2><font face="Verdana, Arial, Helvetica, sans-serif" size="3" color="c5e1ff">Installing 
  your Web Server Certificate</font></h2>
<p><font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"> <font size="1">Your 
  certificate will be sent to you by email. The email message includes the web 
  server certificate that you purchased in the body of the email message. </font></font> 
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Copy 
  the certificate from the body of the email and paste it into a text editor (such 
  as notepad) to create text files.</font><font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"><br>
  </font></p>
<h4><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="c5e1ff">Install 
  your Web Server Certificate</font></h4>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">1. 
  Select the <b>Internet Information Service</b> console within the Administrative 
  Tools menu.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">2. 
  Select the web site (host) for which the certificate was made. <br>
  Right mouse-click and select <b>Properties</b>. </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">3. 
  Select the <b>Directory Security</b> tab.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">4. 
  Select the <b>Server Certificate</b> option.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">5. 
  The Welcome to the Web Server Certificate Wizard windows opens. <br>
  Click <b>OK</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">6. 
  Select <b>Process the pending request and install the certificate</b>. <br>
  Click <b>Next</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">7. 
  Enter the location for the certificate file at the Process a Pending Request 
  window. The file extension may be .txt or .crt instead of .cer (search for files 
  of type &quot;<b>all files</b>&quot;) <br>
  <br>
  </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">After 
  the correct certificate file is selected, click <b>Next</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Verify 
  the Certificate Summary to make sure all information is accurate. <br>
  Click <b>Next</b>. </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  <b>Finish</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  <b>Web Site</b> at the site properties window to edit your SSL Port 443 settings 
  for this web server. Click <b>OK</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Test 
your certificate by connecting to your server. Use the https protocol directive 
(e.g. https://your server/) to indicate you wish to use secure HTTP. The padlock 
icon on your Web browser will be displayed in the locked position if you have 
set up your site properly.</font><font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"><br>
<br>
</font> 
<h2><font face="Verdana, Arial, Helvetica, sans-serif" size="3" color="c5e1ff">Backing 
  up your key pair file</font></h2>
<h4><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="c5e1ff">Creating 
  your Snap-in Management Console</font></h4>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Certificate 
  Snap-in consoles (MMC) are not preconfigured. You will need to configure the 
  Snap-in before you can perform any Export/Import functionality. To configure 
  your Snap-in, follow the steps below. The system administrator will have to 
  create the console.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Go 
  to <b>Start</b>. Select <b>Run</b>, Type <b>mmc</b> and click <b>OK</b>. This 
  will bring up an empty console with no management functionality.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
  on <b>Console</b> select <b>Add/Remove Snap-in</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
  Snap-ins added to box will list only the Console Root. Click <b>Add</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  <b>Certificates</b> and then click <b>Add</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  <b>Computer Account</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
  on <b>Finish</b>. </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
  <b>Close</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Click 
  on <b>OK</b>. </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  </font><font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"><br>
  </font> </p>
<h4><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="c5e1ff">Managing 
  your certificates</font></h4>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Go 
  to the <b>Microsoft Management Console</b> (MMC) and add the Snap-in for Certificates.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  the folders <b>Console Root\Certificates(Local Computer)\Personal\Certificates</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Right 
  click on the certificate to export.<br style='mso-special-character:line-break'>
  </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  <b>All Tasks</b> and <b>Export</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">The 
  Welcome to the Certificate Manager Import Wizard window opens. <br>
  Click <b>Next</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Select 
  <b>Yes, export the private key</b>. Click <b>Next</b>.<br>
  </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Make 
  sure the Personal Information Exchange- PKCS # 12 (.pfx) box is selected.<br>
  <br>
  <b>Warning: Make sure that the &quot;Delete the private key if the export is 
  successful&quot; is <span style='color:red'>NOT</span> checked.</b></font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  <br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Check 
  the box <b>Enable strong protection requires IE5.0, NT4.0 SP4 or above</b>. 
  Select<b> Next</b>.</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Check 
  the box to <b>Include all certificates in the chain</b>.<br style='mso-special-character:line-break'>
  </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"><br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Type 
  and confirm your export password. </font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">(Note: 
  this password field can be left blank, but we recommend using a good password 
  for security)<br>
  </font><font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"><br>
  </font> </p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" color="c5e1ff"><b><font size="1">Warning: 
  If you lose the password, you must purchase another certificate.</font></b><font size="1"><br>
  <br>
  <b>Save</b> the file to a disk or other form of media. You should choose a form 
  of media that you would be able to recover if your system has to be rebuilt. 
  Save this file in a secure location.<br>
  <br>
  <b>*** Microsoft has an alert addressing a problem with exporting and importing 
  certificates.*** </b><br>
  <br>
  Service Pack 2 is intended to correct this problem. There is also a hotfix that 
  may be obtained from Microsoft that must be run prior to exporting and importing 
  your certificate. Please go to the following URL for more information or email 
  us at <a href="mailto:support@geotrust.com">support@geotrust.com</a>.<br>
  <br>
  <a href="http://support.microsoft.com/support/kb/articles/Q261/6/55.ASP">http://support.microsoft.com/support/kb/articles/Q261/6/55.ASP</a></font></font></p>
<p>&nbsp;</p>
<h4><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="c5e1ff">Converting 
  your trial certificates into .crt file format</font></h4>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">You 
  will need to open the certificates using Notepad. (You can find Notepad by going 
  to the Start button at the bottom left hand corner of your screen, click on 
  Run, type the word &quot;notepad&quot; and hit Enter.)<br>
  <br>
  First open Your Trial Certificate and copy the information contained in the 
  encrypted block, including the -----BEGIN----- and the -----END CERTIFICATE----- 
  lines.</font></p>
<p ><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">------BEGIN 
  CERTIFICATE-----<br>
  (encrypted information)<br>
  -----END CERTIFICATE-----</font></p>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff"> 
  Type <b>&quot;yourwebsite.crt&quot;</b> for the filename, and change the file 
  saving type from <b>Text (.txt)</b> to <b>All Files</b>; then Save this file 
  in a location which your server can access.<br>
  </font></p>
<p>&nbsp;</p>
<h4><font face="Verdana, Arial, Helvetica, sans-serif" size="2" color="c5e1ff">To 
  further convert your .crt file into the Microsoft .cer format -</font></h4>
<p><font face="Verdana, Arial, Helvetica, sans-serif" size="1" color="c5e1ff">Double-click 
  on the <b>yourwebsite.crt</b> file to open it into the certificate display. 
  Select the <b>Details</b> tab, then select the <b>Copy to file</b> button. Hit 
  <b>Next</b> on the Certificate Wizard. Select <b>Base-64 encoded X.509 (.CER)</b>, 
  then <b>Next</b>. Select <b>Browse</b> (to locate a destination) and type in 
  the filename yourwebsite. Hit <b>Save</b>. You now have the file <b>yourwebsite.cer</b></font></p>
<p style="text-align : left;" align=LEFT>&nbsp; </p>
</body>
</html>
