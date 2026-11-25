extends RefCounted
## Made by tools/white_knight_textures.py: where each picture of the owner's sheet sits in
## textures/wk_views.webp (atlas pixels). Body views: cx = centre line, sole = the y = 0
## line, ppm = atlas pixels per metre. Helm close-ups: x0 / y0 = the sheet pixel of the
## panel's corner (the helm fit in white_knight.gd is in sheet pixels; K = upscale).

const SIZE := Vector2(2048, 1424)
const K := 2
const VIEWS := {
	"front": {"ox": 8.0, "oy": 8.0, "w": 344.0, "h": 956.0, "cx": 155.0, "sole": 938.0, "ppm": 484.6},
	"back": {"ox": 364.0, "oy": 8.0, "w": 356.0, "h": 956.0, "cx": 175.0, "sole": 940.0, "ppm": 485.6},
	"side_r": {"ox": 736.0, "oy": 8.0, "w": 244.0, "h": 956.0, "cx": 93.0, "sole": 942.0, "ppm": 484.6},
	"side_l": {"ox": 996.0, "oy": 8.0, "w": 248.0, "h": 956.0, "cx": 104.0, "sole": 944.0, "ppm": 487.8},
	"helm_front": {"ox": 8.0, "oy": 980.0, "w": 340.0, "h": 420.0, "x0": 30.0, "y0": 532.0},
	"helm_side": {"ox": 364.0, "oy": 980.0, "w": 284.0, "h": 420.0, "x0": 380.0, "y0": 532.0},
	"helm_back": {"ox": 664.0, "oy": 980.0, "w": 264.0, "h": 420.0, "x0": 540.0, "y0": 532.0},
}
