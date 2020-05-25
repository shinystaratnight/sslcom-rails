# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.sass, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w[ ssl_com.css certassure.css common.sass print.css
                                                  ie.css ie8.css site_report.css buy_now.css ssl_seal.css form.authy.css flags.authy.css common.js shared.js jstz.min.js
                                                  promise.min.js webcrypto-liner.shim.js asmcrypto.min.js elliptic.min.js bundle.umd.min.js bundle.pkcs.umd.min.js
                                                  psl.min.js form.authy.js u2f-api.js Duo-Web-v2.js jquery.timepicker.min.js invoice.css bootstrap_style.sass bootstrap_fix.sass
                                                  jquery.timepicker.min.css delayed/web/application.css font_awesome5.js jquery.prettyLoader.js jquery.prettyPopin.js jquery.prettyPhoto.js]
