# frozen_string_literal: true

module UiHelper
  ICON_PATHS = {
    "menu" => "M4 6h16M4 12h16M4 18h16",
    "home" => "M3 11.5 12 4l9 7.5M5 10v10h14V10M9 20v-6h6v6",
    "building" => "M4 21V3h16v18M8 7h2m4 0h2M8 11h2m4 0h2M8 15h2m4 0h2M9 21v-3h6v3",
    "users" => "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm13 10v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75",
    "user-plus" => "M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm10-4v6m3-3h-6",
    "spark" => "m12 3-1.6 5.4L5 10l5.4 1.6L12 17l1.6-5.4L19 10l-5.4-1.6L12 3Zm-6 12-.8 2.2L3 18l2.2.8L6 21l.8-2.2L9 18l-2.2-.8L6 15Z",
    "target" => "M22 12h-4M6 12H2m10-6V2m0 20v-4m7.1-13.1-2.8 2.8M7.7 16.3l-2.8 2.8m14.2 0-2.8-2.8M7.7 7.7 4.9 4.9M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z",
    "briefcase" => "M9 7V5a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2m6 5a18 18 0 0 1-18 0m1-5h16a1 1 0 0 1 1 1v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a1 1 0 0 1 1-1Z",
    "document" => "M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8l-6-6Zm0 0v6h6M8 13h8M8 17h8",
    "cart" => "M3 3h2l2.4 11.4a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.6L21 7H6m4 13h.01M18 20h.01",
    "receipt" => "M6 2h12v20l-3-2-3 2-3-2-3 2V2Zm3 5h6M9 11h6M9 15h4",
    "box" => "m21 8-9-5-9 5 9 5 9-5ZM3 8v10l9 5 9-5V8M12 13v10",
    "calendar" => "M6 2v4m12-4v4M3 9h18M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2Z",
    "lifebuoy" => "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Zm0-6a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm-7-1 3.5-2m7 0L19 15M9 8.5 7 5m8 3.5L17 5",
    "book" => "M4 3h6a3 3 0 0 1 3 3v15a3 3 0 0 0-3-3H4V3Zm16 0h-4a3 3 0 0 0-3 3v15a3 3 0 0 1 3-3h4V3Z",
    "wrench" => "M14.7 6.3a4 4 0 0 0-5-5l2.1 2.1-2.4 2.4-2.1-2.1a4 4 0 0 0 5 5L20 16.4a2.1 2.1 0 0 1-3 3l-7.7-7.7",
    "shield" => "M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z",
    "settings" => "M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Zm7.4-3.5a7 7 0 0 0-.1-1l2-1.6-2-3.4-2.5 1a8 8 0 0 0-1.7-1L14.7 3h-4l-.4 2.7a8 8 0 0 0-1.7 1L6.1 5.6l-2 3.4 2 1.6a7 7 0 0 0 0 2.8l-2 1.6 2 3.4 2.5-1a8 8 0 0 0 1.7 1l.4 2.7h4l.4-2.7a8 8 0 0 0 1.7-1l2.5 1 2-3.4-2-1.6a7 7 0 0 0 .1-1.4Z",
    "bell" => "M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9Zm-8 12h4",
    "user" => "M20 21a8 8 0 0 0-16 0m8-10a4 4 0 1 0 0-8 4 4 0 0 0 0 8Z",
    "search" => "m21 21-4.4-4.4m2.4-5.6a8 8 0 1 1-16 0 8 8 0 0 1 16 0Z",
    "chevron-left" => "m15 18-6-6 6-6",
    "edit" => "M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4L16.5 3.5Z",
    "trash" => "M3 6h18M8 6V4h8v2m3 0-1 15H6L5 6m4 4v7m6-7v7",
    "plus" => "M12 5v14M5 12h14",
    "download" => "M12 3v12m0 0 5-5m-5 5-5-5M4 21h16",
    "upload" => "M12 21V9m0 0 5 5m-5-5-5 5M4 3h16",
    "list" => "M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01",
    "lock" => "M6 10V7a6 6 0 0 1 12 0v3M5 10h14v11H5V10Zm7 4v3",
    "clock" => "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Zm0-15v5l3 2",
    "globe" => "M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20Zm0 0c3 0 5-4.5 5-10S15 2 12 2 7 6.5 7 12s2 10 5 10ZM2 12h20",
    "phone" => "M22 16.9v3a2 2 0 0 1-2.2 2 19.8 19.8 0 0 1-8.6-3.1 19.5 19.5 0 0 1-6-6A19.8 19.8 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7c.1 1 .4 2 .7 2.8a2 2 0 0 1-.5 2.1L8 9.9a16 16 0 0 0 6 6l1.3-1.3a2 2 0 0 1 2.1-.5c.9.3 1.8.6 2.8.7A2 2 0 0 1 22 16.9Z",
    "mail" => "M3 5h18v14H3V5Zm0 1 9 7 9-7",
    "check-square" => "M9 11l3 3L22 4M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11",
    "message" => "M21 15a4 4 0 0 1-4 4H8l-5 3V7a4 4 0 0 1 4-4h10a4 4 0 0 1 4 4v8Z",
    "send" => "m22 2-7 20-4-9-9-4 20-7ZM11 13l4-4",
    "trophy" => "M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0V4Zm0 2H3v2a4 4 0 0 0 4 4m10-6h4v2a4 4 0 0 1-4 4",
    "timeline" => "M4 6h6M4 12h10M4 18h16M18 5v2M14 11v2M10 17v2",
    "star" => "m12 2 3.1 6.3 6.9 1-5 4.9 1.2 6.8-6.2-3.2L5.8 21 7 14.2 2 9.3l6.9-1L12 2Z",
    "medal" => "M12 15a5 5 0 1 0 0-10 5 5 0 0 0 0 10Zm-3 0-2 7 5-3 5 3-2-7",
    "transform" => "M17 3l4 4-4 4M3 7h18M7 21l-4-4 4-4m14 4H3",
    "more" => "M5 12h.01M12 12h.01M19 12h.01",
    "x" => "M18 6 6 18M6 6l12 12"
  }.freeze

  def ui_icon(name, size: 20, class_name: nil)
    path = ICON_PATHS.fetch(name.to_s, ICON_PATHS.fetch("document"))
    tag.svg(class: class_name, width: size, height: size, viewBox: "0 0 24 24", fill: "none",
      stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round",
      aria: {hidden: true}) { tag.path(d: path) }
  end

  def navigation_path(entry)
    entry.path ? public_send(entry.path) : records_path(object_type: entry.object_type)
  end

  def display_name(record)
    Crm::RecordPresentation.display_name(record)
  end
end
