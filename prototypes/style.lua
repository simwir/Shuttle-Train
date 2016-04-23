data:extend(
	{
	  {
		type = "font",
		name = "shuttle-train-font",
		from = "default",
		size = 12
	  },
	  {
		type = "font",
		name = "shuttle-train-font-bold",
		from = "default-bold",
		size = 16
	  }
	}
)

data.raw["gui-style"].default["st_label_title"] =
{
	type = "label_style",
	parent = "label_style",
	width = 130,
	align = "center",
	font = "shuttle-train-font-bold",
	font_color = {r = 1, g = 1, b = 1}
}

data.raw["gui-style"].default["st-station-button"] =
{
	type = "button_style",
	parent = "button_style",
	font = "shuttle-train-font",
	default_font_color = {r = 1, g = 1, b = 1},
	align = "center",
	minimal_width = 130,
	top_padding = 5,
	right_padding = 5,
	bottom_padding = 5,
	left_padding = 5,
	default_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 0}
	},
	hovered_font_color = {r = 1, g = 1, b = 1},
	hovered_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 8}
	},
	clicked_font_color = {r = 1, g = 1, b = 1},
	clicked_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 16}
	},
	disabled_font_color = {r = 0.5, g = 0.5, b = 0.5},
	disabled_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 0}
	},
	pie_progress_color = {r = 1, g = 1, b = 1},
	left_click_sound =
	{
		filename = "__core__/sound/gui-click.ogg",
		volume = 1
	}
}

data.raw["gui-style"].default["st-nav-button"] =
{
	type = "button_style",
	parent = "button_style",
	font = "shuttle-train-font",
	default_font_color = {r = 1, g = 1, b = 1},
	align = "center",
	top_padding = 5,
	right_padding = 5,
	bottom_padding = 5,
	left_padding = 5,
	default_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 0}
	},
	hovered_font_color = {r = 1, g = 1, b = 1},
	hovered_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 8}
	},
	clicked_font_color = {r = 1, g = 1, b = 1},
	clicked_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 16}
	},
	disabled_font_color = {r = 0.5, g = 0.5, b = 0.5},
	disabled_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		priority = "extra-high-no-scale",
		corner_size = {3, 3},
		position = {0, 0}
	},
	pie_progress_color = {r = 1, g = 1, b = 1},
	left_click_sound =
	{
		filename = "__core__/sound/gui-click.ogg",
		volume = 1
	}
}

data.raw["gui-style"].default["st-nav-button-disabled"] =
{
	type = "button_style",
	parent = "st-nav-button",
	default_font_color = {r = 0.34, g = 0.34, b = 0.34},
	hovered_font_color = {r = 0.34, g = 0.34, b = 0.38},
	hovered_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		corner_size = {3, 3},
		position = {0, 0}
	},
	clicked_font_color = {r = 0.34, g = 0.34, b = 0.38},
	clicked_graphical_set =
	{
		type = "composition",
		filename = "__core__/graphics/gui.png",
		corner_size = {3, 3},
		position = {0, 0}
    },
}
