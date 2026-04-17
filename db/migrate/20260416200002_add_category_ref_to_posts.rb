# Migration: add_category_ref_to_posts
#
# Adds a nullable category_id foreign key to the posts table so each post can
# belong to at most one category. Nullable because existing posts have no
# category and authors are not required to assign one.
#
# Rails add_reference automatically creates an index on category_id, which
# covers the common query of fetching all posts in a given category.

class AddCategoryRefToPosts < ActiveRecord::Migration[7.2]
  def change
    add_reference :posts, :category, null: true, foreign_key: true
  end
end
