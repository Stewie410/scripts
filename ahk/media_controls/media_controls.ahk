#Requires AutoHotkey v2.0

; @untested
class MediaControls {
	static toggle_play_pause() {
		Send "{Media_Play_Pause}"
	}

	static next() {
		Send "{Media_Next}"
	}

	static prev() {
		Send "{Media_Prev}"
	}

	static toggle_mute() {
		SoundSetMute(-1)
	}

	static mute() {
		SoundSetMute(1)
	}

	static unmute() {
		SoundSetMute(0)
	}

	static volume_inc(amount := 5) {
		SoundSetVolume("+" . amount)
	}

	static volume_dec(amount := 5) {
		SoundSetVolume("-" . amount)
	}

	static volume_set(amount) {
		SoundSetVolume(amount)
	}
}