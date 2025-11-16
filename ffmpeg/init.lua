local defines = FFILoader.LoadDefinitions(
	{"libav", "libsw"},
	"ffmpeg/ffmpeg.i", {
		UINT8_C = function(val) return val end,
		UINT16_C = function(val) return val end,
		UINT32_C = function(val) return val end,
		UINT64_C = function(val) return val end,

		MKTAG = true,
		FFERRTAG = function(a, b, c, d)
			return -bit.bor(
				type(a) == "string" and string.byte(a) or a, 
				bit.lshift(type(b) == "string" and string.byte(b) or b, 8),
				bit.lshift(type(c) == "string" and string.byte(c) or c, 16),
				bit.lshift(type(d) == "string" and string.byte(d) or d, 24)
			)
		end
	}
)

defines.AVERROR_EAGAIN = -11

local ffmpeg = {
	avutil = FFILoader.CreateLibrary("avutil-60", defines, true),
	avcodec = FFILoader.CreateLibrary("avcodec-62", defines, true),
	avformat = FFILoader.CreateLibrary("avformat-62", defines, true),
	avdevice = FFILoader.CreateLibrary("avdevice-62", defines, true),
	avfilter = FFILoader.CreateLibrary("avfilter-11", defines, true),
	swscale = FFILoader.CreateLibrary("swscale-9", defines, true)
}

return ffmpeg