# == Schema Information
#
# Table name: notes
#
#  id           :integer          not null, primary key
#  notable_type :string(255)
#  note         :text(65535)
#  title        :string(50)       default("")
#  created_at   :datetime
#  updated_at   :datetime
#  notable_id   :integer
#  user_id      :integer
#
# Indexes
#
#  index_notes_on_notable_id                   (notable_id)
#  index_notes_on_notable_id_and_notable_type  (notable_id,notable_type)
#  index_notes_on_notable_type                 (notable_type)
#  index_notes_on_user_id                      (user_id)
#

class Note < ApplicationRecord

  include ActsAsNotable::Note

  belongs_to :notable, :polymorphic => true

  default_scope{ order("created_at asc")}

  # NOTE: install the acts_as_votable plugin if you
  # want user to vote on the quality of notes.
  #acts_as_voteable

  # NOTE: Notes belong to a user
  belongs_to :user

end
