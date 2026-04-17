# == Schema Information
#
# Table name: posts
#
#  id         :bigint           not null, primary key
#  title      :string           not null
#  status     :integer          default("draft"), not null
#  author_id  :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Post < ApplicationRecord
  belongs_to :author, class_name: "User"

  has_rich_text :body

  belongs_to :category, optional: true
  has_many :taggings, dependent: :destroy
  has_many :tags, through: :taggings

  enum :status, { draft: 0, in_review: 1, published: 2, archived: 3 }, validate: true

  validates :title, presence: true

  class InvalidTransition < StandardError; end

  def submit_for_review!
    raise InvalidTransition, "Post must be draft to submit for review" unless draft?
    update!(status: :in_review)
  end

  def publish!
    raise InvalidTransition, "Post must be in review to publish" unless in_review?
    update!(status: :published)
  end

  def reject!
    raise InvalidTransition, "Post must be in review to reject" unless in_review?
    update!(status: :draft)
  end

  def archive!
    raise InvalidTransition, "Post must be published to archive" unless published?
    update!(status: :archived)
  end
end
