local colors = require("colors")

-- Floating Material You bar
sbar.bar({
	height = 36,
	color = colors.bar.bg,
	border_color = colors.bar.border,
	border_width = 0,
	corner_radius = 14,
	margin = 8,
	y_offset = 6,
	blur_radius = 30,
	padding_right = 6,
	padding_left = 6,
	topmost = "window",
})
