module PostsHelper
  STATUS_BADGE_CLASSES = {
    "draft"     => "bg-[#f1f5f9] text-[#475569]",
    "in_review" => "bg-[#fef9c3] text-[#854d0e]",
    "published" => "bg-[#dcfce7] text-[#166534]",
    "archived"  => "bg-[#f1f5f9] text-[rgba(4,14,32,0.50)]"
  }.freeze

  def status_badge_classes(status)
    STATUS_BADGE_CLASSES.fetch(status.to_s, "bg-gray-100 text-gray-700")
  end
end
