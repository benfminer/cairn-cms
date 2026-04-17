# Migration: create_categories_tags_taggings
#
# Introduces the taxonomy system for posts:
#   - categories: a controlled vocabulary for primary classification (one per post)
#   - tags:       a freeform vocabulary for secondary classification (many per post)
#   - taggings:   the join table associating posts with tags
#
# Each category and tag has a unique slug for use in URLs and lookups.
# The taggings table enforces uniqueness on (post_id, tag_id) so the same
# tag cannot be applied to the same post more than once.

class CreateCategoriesTagsTaggings < ActiveRecord::Migration[7.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :categories, :slug, unique: true

    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :tags, :slug, unique: true

    create_table :taggings do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag,  null: false, foreign_key: true
      t.timestamps
    end
    add_index :taggings, [:post_id, :tag_id], unique: true
  end
end
