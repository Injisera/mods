data:extend({{
  type = "selection-tool",
  name = "construction-planner-item",
  icon_size = 64,
  icon = "__base__/graphics/icons/deconstruction-planner.png",
  subgroup = "tool",
  stack_size=1,

  selection_color = {0, 1, 0},
  selection_mode = {"blueprint"},
  selection_cursor_box_type = "copy",

  alt_selection_color = {0,0.5,0},
  alt_selection_mode = {"nothing"},
  alt_selection_cursor_box_type = "copy",
  show_in_library = false,
  flags = {"hidden", "only-in-cursor"}
}})
