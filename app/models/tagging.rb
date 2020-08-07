class Tagging < ApplicationRecord
  belongs_to :tag
  belongs_to :taggable, polymorphic: true

  before_create :unique_taggings
  after_create  :increment_tag
  after_destroy :decrement_tag

  validates :tag_id, :taggable_type, :taggable_id, presence: true, allow_blank: false

  private

  def unique_taggings
    errors.clear

    dup = Tagging.where(
      taggable_type: taggable_type, taggable_id: taggable_id, tag_id: tag_id
    ).any?
    errors.add(:tag, message: 'Duplicate tag.') if dup
  end

  def increment_tag
    tag.increment!(:taggings_count)
  end

  def decrement_tag
    tag.decrement!(:taggings_count)
  end
end
