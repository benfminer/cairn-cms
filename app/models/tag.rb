class Tag < ApplicationRecord
  has_many :taggings, dependent: :destroy
  has_many :posts, through: :taggings

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { name_changed? || slug.blank? }

  private

  def generate_slug
    self.slug = name.to_s.parameterize
  end
end
