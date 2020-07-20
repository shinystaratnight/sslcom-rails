# frozen_string_literal: true

class  VerificationsController < ApplicationController
  before_action :current_user
  before_action :require_user

  def index; end
end
