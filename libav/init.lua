local defines = FFILoader.LoadDefinitions(
	{"libav", "libsw"},
	"libav/libav.i", {
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

local libav

if jit.os == "Windows" then
	libav = {
		avutil = FFILoader.CreateLibrary("avutil-"..tostring(defines.LIBAVUTIL_VERSION_MAJOR), defines, true),
		avcodec = FFILoader.CreateLibrary("avcodec-"..tostring(defines.LIBAVCODEC_VERSION_MAJOR), defines, true),
		avformat = FFILoader.CreateLibrary("avformat-"..tostring(defines.LIBAVFORMAT_VERSION_MAJOR), defines, true),
		avdevice = FFILoader.CreateLibrary("avdevice-"..tostring(defines.LIBAVDEVICE_VERSION_MAJOR), defines, true),
		avfilter = FFILoader.CreateLibrary("avfilter-"..tostring(defines.LIBAVFILTER_VERSION_MAJOR), defines, true),
		swscale = FFILoader.CreateLibrary("swscale-"..tostring(defines.LIBSWSCALE_VERSION_MAJOR), defines, true)
	}
else
	libav = {
		avutil = FFILoader.CreateLibrary("avutil.so."..tostring(defines.LIBAVUTIL_VERSION_MAJOR), defines, true),
		avcodec = FFILoader.CreateLibrary("avcodec.so."..tostring(defines.LIBAVCODEC_VERSION_MAJOR, defines), true),
		avformat = FFILoader.CreateLibrary("avformat.so."..tostring(defines.LIBAVFORMAT_VERSION_MAJOR), defines, true),
		avdevice = FFILoader.CreateLibrary("avdevice.so."..tostring(defines.LIBAVDEVICE_VERSION_MAJOR), defines, true),
		avfilter = FFILoader.CreateLibrary("avfilter.so."..tostring(defines.LIBAVFILTER_VERSION_MAJOR), defines, true),
		swscale = FFILoader.CreateLibrary("swscale.so."..tostring(defines.LIBSWSCALE_VERSION_MAJOR), defines, true)
	}
end

return libav