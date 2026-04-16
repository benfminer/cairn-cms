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

  enum :status, { draft: 0, in_review: 1, published: 2, archived: 3 }, validate: true

  validates :title, presence: true
end
