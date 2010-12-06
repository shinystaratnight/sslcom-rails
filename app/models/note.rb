class Note < ActiveRecord::Base

  include ActsAsNotable::Note

  belongs_to :notable, :polymorphic => true

  default_scope :order => 'created_at ASC'

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of notes.
  #acts_as_voteable

  # NOTE: Notes belong to a user
  belongs_to :user

end
