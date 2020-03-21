# frozen_string_literal: true

# wkhtmltopdf binary downloads: https://wkhtmltopdf.org/downloads.html

# Installing latest builds of wkhtmltopdf and wkhtmltoimage on linux (e.g.: 0.12.4)
#   download=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz
#   wget $download -O wkhtmltox.tar.xz
#   tar xf wkhtmltox.tar.xz
#   sudo mv wkhtmltox/bin/* bin/wkhtmltopdf
#   rm -Rf wkhtmltox*
#   sudo mv bin/wkhtmltopdf/wkhtmltopdf bin/wkhtmltopdf/wkhtmltox-0.12.4_linux-generic-amd64

wkhtmltopdf_executable = if Rails.env.production? || Rails.env.staging?
                           Rails.root.join('bin', 'wkhtmltopdf', 'wkhtmltox-0.12.4_linux-generic-amd64').to_s
                         elsif RUBY_PLATFORM.match?(/linux/)
                           Rails.root.join('bin', 'wkhtmltopdf', 'wkhtmltox-0.12.4_linux-generic-amd64').to_s
                         elsif RUBY_PLATFORM.match?(/mingw32/)
                           'C:\Program Files (x86)\wkhtmltopdf\wkhtmltopdf.exe'
                         else
                           Rails.root.join('bin', 'wkhtmltopdf', 'wkhtmltox-0.12.4_osx-cocoa-x86-64.pkg').to_s
                         end

WickedPdf.config = {
  disposition: 'attachment',
  exe_path: wkhtmltopdf_executable,
  page_size: 'A4',
  disable_smart_shrinking: true,
  footer: { left: '[page] of [topage] | Thank you for using SSL.com. For assistance, please email Sales@SSL.com or visit SSL.com.' }
}
