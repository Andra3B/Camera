local bit = require("bit")

local libraries

if jit.os == "Windows" then
	libraries = {
		{"avutil", "avutil-60"},
		{"avcodec", "avcodec-62"},
		{"avformat", "avformat-62"},
		{"avdevice", "avdevice-62"},
		{"avfilter", "avfilter-11"},
		{"swscale", "swscale-9"}
	}
else
	libraries = {
		{"avutil", "avutil-59"},
		{"avcodec", "avcodec-61"},
		{"avformat", "avformat-61"},
		{"avdevice", "avdevice-61"},
		{"avfilter", "avfilter-10"},
		{"swscale", "swscale-8"}
	}
end

local function FFERRTAG(a, b, c, d)
	return -bit.bor(
		type(a) == "string" and string.byte(a) or a, 
		bit.lshift(type(b) == "string" and string.byte(b) or b, 8),
		bit.lshift(type(c) == "string" and string.byte(c) or c, 16),
		bit.lshift(type(d) == "string" and string.byte(d) or d, 24)
	)
end

require("FFILoader").CreateBindings({"libav", "libsw"}, "libav/libav.i", libraries, ".", "libav", {
		UINT8_C = function(val) return val end,
		UINT16_C = function(val) return val end,
		UINT32_C = function(val) return val end,
		UINT64_C = function(val) return val end,

		MKTAG = true,
		AVERROR_EAGAIN = -11,
		AVERROR_EINVAL = -22,
		AVERROR_ENOMEM = -12,
		["FFERRTAG"] = FFERRTAG,
		
		AV_CODEC_FLAG_LOW_DELAY = bit.lshift(1, 19)
	}, nil
)

print("libav built!")