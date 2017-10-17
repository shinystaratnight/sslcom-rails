class Api::V1::APIController < ApplicationController
  before_filter :set_test, :record_parameters
  skip_filter :identify_visitor, :record_visit, :verify_authenticity_token
  
  TEST_SUBDOMAIN = 'sws-test'
  
end
