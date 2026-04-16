module PostsHelper
  STATUS_BADGE_CLASSES = {
    "draft"     => "bg-gray-100 text-gray-700",
    "in_review" => "bg-yellow-100 text-yellow-800",
    "published" => "bg-green-100 text-green-800",
    "archived"  => "bg-red-100 text-red-700"
  }.freeze

  def status_badge_classes(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-gray-100 text-gray-700")
  end
end
