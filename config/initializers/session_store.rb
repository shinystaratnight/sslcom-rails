# Be sure to restart your server when you modify this file.

session_params= if Rails.env=~/development/
                  {key: '_ssl_com4_session', domain:".ssl.local"}
                else
                  {key: '_ssl_com3_session', domain: ".ssl.com", expires: 20.minutes}
                end
SslCom::Application.config.session_store :cookie_store, session_params

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
#SslCom::Application.config.session_store :active_record_store
