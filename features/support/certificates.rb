Before('@setup_certificates') do
  @lobby_sb_betsoftgaming_com_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIBtTCCAR4CAQAwdTELMAkGA1UEBhMCQ1kxEDAOBgNVBAgTB05pY29zaWExEjAQ
BgNVBAcTCVN0cm92b2xvczEbMBkGA1UEChMSQmV0c29mdGdhbWluZyBMVEQuMSMw
IQYDVQQDExpsb2JieS5zYi5iZXRzb2Z0Z2FtaW5nLmNvbTCBnzANBgkqhkiG9w0B
AQEFAAOBjQAwgYkCgYEAsrTRXbve5Y7dhSorB11hIkHqbKZgxbDPQ2w0BacHIx2U
7M1RtyXaPYizUXHOrjCiCoe9NyivZ9Oip63kfIb5vpArIgVfnM2K2aizcmi6pdj2
kbePrp1Uz86nxxbEso013XWlmu2lgTRTeBETeRFebYzSKH7hHvFR37kaQRIdHckC
AwEAAaAAMA0GCSqGSIb3DQEBBQUAA4GBADAknB7B/3CnvuZUJrH5O6oD3USft4QU
uuMti01ffH4ZyTMfyLdDcd0gdeXPej+JGvScuXPjzpMb92cpfufTRKsTBUG1C2T6
TYrJ9O3d5oKph8nICihGT0fDIqJCzGar6W9ZbL8PiIDL4hFymVUZk409NPfrND1g
yIeY8v/sjOUW
-----END CERTIFICATE REQUEST-----
EOS

  @lobby_sb_betsoftgaming_com_signed_cert = <<EOS
-----BEGIN CERTIFICATE-----
MIIDoDCCAoigAwIBAgIFMUeG4iswDQYJKoZIhvcNAQEFBQAwSDELMAkGA1UEBhMC
VVMxIDAeBgNVBAoTF1NlY3VyZVRydXN0IENvcnBvcmF0aW9uMRcwFQYDVQQDEw5T
ZWN1cmVUcnVzdCBDQTAeFw0xMDA1MDExODE3MDZaFw0xMTA0MjcxODE3MDZaMHAx
CzAJBgNVBAYTAkNZMRAwDgYDVQQIEwdOaWNvc2lhMRAwDgYDVQQHEwdOaWNvc2lh
MRgwFgYDVQQKEw9EaWdpdHVzIExpbWl0ZWQxIzAhBgNVBAMTGmxvYmJ5LnNiLmJl
dHNvZnRnYW1pbmcuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCytNFd
u97ljt2FKisHXWEiQepspmDFsM9DbDQFpwcjHZTszVG3Jdo9iLNRcc6uMKIKh703
KK9n06KnreR8hvm+kCsiBV+czYrZqLNyaLql2PaRt4+unVTPzqfHFsSyjTXddaWa
7aWBNFN4ERN5EV5tjNIofuEe8VHfuRpBEh0dyQIDAQABo4HsMIHpMAkGA1UdEwQC
MAAwHQYDVR0OBBYEFFK4/upUAJGFGUfIHDATHx7ZlERdMB8GA1UdIwQYMBaAFEIy
thb6BP3+XUt6w/33TEAdWkOvMAsGA1UdDwQEAwIFoDATBgNVHSUEDDAKBggrBgEF
BQcDATA0BgNVHR8ELTArMCmgJ6AlhiNodHRwOi8vY3JsLnNlY3VyZXRydXN0LmNv
bS9TVENBLmNybDBEBgNVHSAEPTA7MDkGDGCGSAGG/WQBAQIDATApMCcGCCsGAQUF
BwIBFhtodHRwOi8vc3NsLnRydXN0d2F2ZS5jb20vQ0EwDQYJKoZIhvcNAQEFBQAD
ggEBADWc9B0SZCWfV1twxJGliUSUQOECP8rGlcrbeBfWuhwv+pJh7L9zE+Y233YH
yjEuveGSaz2jUCbFMA1OQZP5xQkrgNyP1HS+TRBhueiEklQ7Y8hl1fJqzN/9dE8L
s6XXG8ikdc5d/TjyAn0uBdvvd6u7cgrj3mFmnaqsrRkxRiEIy9Mar3KEF9NRD/fY
KcU+G+C2Pz1K2UQ6KitgAAJ5LrUXCee8hDyXgqHhsLn0ladREwCI3Nex/tX3vS4u
zRz1OP0WypXzhmrjUKyFiNNBzJRBQOJmJn/+65Ag2RD7sMNT5exOc/jTjG7PIKBN
KwcYNFqMjaFueahoRcU/Xquksb8=
-----END CERTIFICATE-----
EOS

  @star_arrownet_dk_csr = <<EOS
-----BEGIN CERTIFICATE REQUEST-----
MIIB0TCCAToCAQAwgZAxCzAJBgNVBAYTAkRLMRAwDgYDVQQIEwdEZW5tYXJrMREw
DwYDVQQHEwhCcm9lbmRieTEVMBMGA1UEChMMQXJyb3duZXQgQS9TMQwwCgYDVQQL
EwNDU0QxFjAUBgNVBAMUDSouYXJyb3duZXQuZGsxHzAdBgkqhkiG9w0BCQEWEGlu
Zm9AYXJyb3duZXQuZGswgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAOYnCB7/
Pc+2XHyxpb1Is3OCgGhCsYXwf6my4on1brYY2IgIE3BLUU/n5f0oZP8jzNntIGHW
XLVPx6x5Sn1n19pP/lGkN9p3ug5NXtK/F7c5CrzBPltdWgykhN1Nkzu0qMAldes2
tFa5rWmd01cH03p5djxShMgLp75Y9NvmIln3AgMBAAGgADANBgkqhkiG9w0BAQQF
AAOBgQCxHoV1wdt7W03wGVPf6Ywkcc6t0zL51CF3HZg3YAFjHYYt0NSGMvXuP3w6
wUDIoXtUsuhxzw8ynNv6bCE0zy00rOwJLNh/odokaxTOkImIXuly8x91ugglOddL
yb5Gu/g2Lig5QzuvMvNw6v4y2eZo22H2gzS2xR97Pexiexx3UQ==
-----END CERTIFICATE REQUEST-----
EOS

  @star_arrownet_dk_cert = <<EOS
-----BEGIN CERTIFICATE-----
MIIFcjCCBFqgAwIBAgIRAJv0VoG7rK1HnFd5FJJhJnUwDQYJKoZIhvcNAQEFBQAw
gZcxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR8wHQYDVQQDExZVVE4tVVNFUkZpcnN0
LUhhcmR3YXJlMB4XDTA5MTEyNTAwMDAwMFoXDTExMTEyNTIzNTk1OVowgfAxCzAJ
BgNVBAYTAkRLMQ0wCwYDVQQREwQyNjIwMRAwDgYDVQQIEwdEZW5tYXJrMREwDwYD
VQQHEwhCcm9lbmRieTEWMBQGA1UECRMNUm9ob2xtc3ZlaiAxOTEVMBMGA1UEChMM
QXJyb3duZXQgQS9TMQwwCgYDVQQLEwNDU0QxMzAxBgNVBAsTKkhvc3RlZCBieSBT
ZWN1cmUgU29ja2V0cyBMYWJvcmF0b3JpZXMsIExMQzEjMCEGA1UECxMaQ29tb2Rv
IFByZW1pdW1TU0wgV2lsZGNhcmQxFjAUBgNVBAMUDSouYXJyb3duZXQuZGswgZ8w
DQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAOYnCB7/Pc+2XHyxpb1Is3OCgGhCsYXw
f6my4on1brYY2IgIE3BLUU/n5f0oZP8jzNntIGHWXLVPx6x5Sn1n19pP/lGkN9p3
ug5NXtK/F7c5CrzBPltdWgykhN1Nkzu0qMAldes2tFa5rWmd01cH03p5djxShMgL
p75Y9NvmIln3AgMBAAGjggHgMIIB3DAfBgNVHSMEGDAWgBShcl8mGyiYQ5VdBzfV
hZadS9LDRTAdBgNVHQ4EFgQUqlO4tDuvnBIom6RjRnVXAgle5YcwDgYDVR0PAQH/
BAQDAgWgMAwGA1UdEwEB/wQCMAAwHQYDVR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUF
BwMCMEYGA1UdIAQ/MD0wOwYMKwYBBAGyMQECAQMEMCswKQYIKwYBBQUHAgEWHWh0
dHBzOi8vc2VjdXJlLmNvbW9kby5uZXQvQ1BTMHsGA1UdHwR0MHIwOKA2oDSGMmh0
dHA6Ly9jcmwuY29tb2RvY2EuY29tL1VUTi1VU0VSRmlyc3QtSGFyZHdhcmUuY3Js
MDagNKAyhjBodHRwOi8vY3JsLmNvbW9kby5uZXQvVVROLVVTRVJGaXJzdC1IYXJk
d2FyZS5jcmwwcQYIKwYBBQUHAQEEZTBjMDsGCCsGAQUFBzAChi9odHRwOi8vY3J0
LmNvbW9kb2NhLmNvbS9VVE5BZGRUcnVzdFNlcnZlckNBLmNydDAkBggrBgEFBQcw
AYYYaHR0cDovL29jc3AuY29tb2RvY2EuY29tMCUGA1UdEQQeMByCDSouYXJyb3du
ZXQuZGuCC2Fycm93bmV0LmRrMA0GCSqGSIb3DQEBBQUAA4IBAQCeSd1SG5gbUG8D
AdBW1nR3vAb0s8Hg1DWOAsRwPoNOQWvYeiayUEnYgtWoD2QLhHSxu5qz5LQuKMwW
6MF+5pbwpwiDFv+dKQHz8Ym5MhjgvosJT/vcvR27bQAbryrTT+3jM7vCZ/dA140T
kmGEby8i9wMvG0LmhSDQg1x/CL6sehHoowaNNtZ3sshaekKgUcthkyzOy+y9Hef7
wgu8DujpRyEcAlUXgD+KIKonfUYMRWji/VBZgKjCyuGpK4uL0OmPEnShagLYgGLd
YefSExBnHUItfHe7ABcxH66dPaQHfhForDD9TL8KtSzP3whwSQhQ2uH51J279IfB
EyM422Ir
-----END CERTIFICATE-----
EOS
end