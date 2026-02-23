require("Setup")

local libraries

if jit.os == "Windows" then
	libraries = {
		["avutil"] = "avutil-59",
		["avcodec"] = "avcodec-61",
		["avformat"] = "avformat-61",
		["avdevice"] = "avdevice-61",
		["avfilter"] = "avfilter-10",
		["swscale"] = "swscale-8"
	}
else
	libraries = {
		["avutil"] = "avutil.so.59",
		["avcodec"] = "avcodec.so.61",
		["avformat"] = "avformat.so.61",
		["avdevice"] = "avdevice.so.61",
		["avfilter"] = "avfilter.so.10",
		["swscale"] = "swscale.so.8"
	}
end

require("FFILoader").CreateBindings({"libav", "libsw"}, "libav/libav.i", libraries, ".", "libav", {
		UINT8_C = function(val) return val end,
		UINT16_C = function(val) return val end,
		UINT32_C = function(val) return val end,
		UINT64_C = function(val) return val end,

		MKTAG = true,
		AVERROR_EAGAIN = -11,
		FFERRTAG = function(a, b, c, d)
			return -bit.bor(
				type(a) == "string" and string.byte(a) or a, 
				bit.lshift(type(b) == "string" and string.byte(b) or b, 8),
				bit.lshift(type(c) == "string" and string.byte(c) or c, 16),
				bit.lshift(type(d) == "string" and string.byte(d) or d, 24)
			)
		end
	}, nil
)

print("libav built!")