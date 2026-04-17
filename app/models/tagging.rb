# == Schema Information
#
# Table name: taggings
#
#  id         :bigint           not null, primary key
#  post_id    :bigint           not null
#  tag_id     :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Tagging < ApplicationRecord
  belongs_to :post
  belongs_to :tag

  validates :tag_id, uniqueness: { scope: :post_id }
end
