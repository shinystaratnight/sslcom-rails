# Controller
require 'uuidtools'

class People < ActionController::Base

  # ... Other REST actions

  def create
    count = Person.count + 1
    name = count.odd? ? "UnicornRainbows" : "LaserScorpions"
    @person = Person.new(params[:person])

    # not sure if slug must maintain this pattern, but we could shorten it if it only needs uniqueness
    if @person.update_attributes(
        {slug: UUIDTools::UUID.random_create.to_s, admin: false, handle: name + count.to_s, team: name})
      Emails.validation_email(@person).deliver
      Emails.admin_new_user(get_admins, @person).deliver
      redirect_to @person, notice: "Account added!"
    else
      render :new
    end
  end

  private

  def validateEmail
    if !!(@user = Person.find_by_slug(params[:slug]))
      @user.update_attribute :validated, true
      Rails.logger.info "USER: User ##{@person.id} validated email successfully."
      Emails.admin_user_validated(get_admins, @user).deliver
      Emails.welcome(@user).deliver
    end
  end

  def get_admins
    @admins = Person.where(admin: true)
  end

end


# Model

class Person < ActiveRecord::Base
  attr_accessible :first_name, :last_name, :email, :admin, :slug, :validated, :handle, :team
end


# Mailer

class Emails < ActionMailer::Base
  default :from => 'foo@example.com'

  # would be better to consolidate the following functions, but I'm not sure where else in the app the different
  # methods are referenced, and also the views for each will surely be different

  %w(welcome validation_email).each do |func|
    define_method("#{func}") do |person|
      @person = person
      mail to: @person
    end
  end

  %w(admin_user_validated admin_new_user admin_removing_unvalidated_users).each do |func|
    define_method("#{func}") do |admins, user|
      @admins = admins.map(&:email) rescue []
      eval("@user#{'s' if func=~/admin_removing_unvalidated_users/}=user")
      mail to: @admins
    end
  end
end


# Rake Task

namespace :accounts do
	
  desc "Remove accounts where the email was never validated and it is over 30 days old"
  task :remove_unvalidated do
    @people = Person.select([:id,:email]).where('created_at < ?', 30.days.ago).where(validated: false)
    Rails.logger.info "Removing unvalidated users #{@people.map(&:email).join(", ")}"
    Emails.admin_removing_unvalidated_users(Person.where(admin: true), @people).deliver
    @people.destroy_all
  end
	
end
