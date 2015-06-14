# Be sure to restart your server when you modify this file.

session_params= if DEPLOYMENT_CLIENT=~/certassure/
                  {:key => '_certassure_session', :domain=>".certassure.com"}
                else
                  {:key => '_ssl_com3_session', :domain=>".ssl.com"}
                end
SslCom::Application.config.session_store :cookie_store, session_params

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
#SslCom::Application.config.session_store :active_record_store
