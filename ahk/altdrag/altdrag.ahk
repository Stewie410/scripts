#Requires AutoHotkey v2.0

; @untested
class AltDrag {
	static move() {
		CoordMode("Mouse")
		MouseGetPos(&ox, &oy, &id)
		while GetKeyState("LButton", "P") {
			MouseGetPos(&cx, &cy)
			WinGetPos(&wx, &wy)
			WinMove(wx + cx - ox, wy + cy - oy, "ahk_id " . id)
			ox := cx
			oy := cy
			Sleep(10)
		}
	}

	static resize() {
		CoordMode("Mouse")
		MouseGetPos(&omx, &omy, &id)
		WinGetPos(&owx, &owy, &oww, &owh, "ahk_id " . id)

		rx := (omx - owx) / oww - 0.5
		ry := (omy - owy) / owh - 0.5
		north := 2 * ry + Abs(rx) < 0
		south := 2 * ry - Abs(rx) > 0
		east :=  2 * rx + Abs(ry) > 0
		west :=  2 * rx - Abs(ry) < 0

		while GetKeyState("RButton", "P") {
			CoordMode("Mouse")
			MouseGetPos(&cx, &cy)
			WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " . id)
			dx := mx - omx
			dy := my - omy
			WinMove(
				west ? wx + dx : wx,
				north ? wy + dy : wy,
				ww + wx - mx + (east ? dx : 0),
				wh + wy - my + (south ? dy : 0)
			)
			omx := mx
			omy := my
		}
	}
}