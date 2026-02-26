local Log = {}

Enum.LogPriority = Enum.Create({
    Trace = 1,
    Verbose = 2,
    Debug = 3,
    Info = 4,
    Warn = 5,
    Error = 6,
    Critical = 7
})

local currentPriority = Enum.LogPriority.Info

function Log.DefaultWriter(category, priority, message, ...)
	io.stdout:write(Log.Format(category, priority, nil, message, ...).."\n")
end

local currentWriter = Log.DefaultWriter

function Log.Format(category, priority, time, message, ...)
	return string.format("[%s] [%s:%s] "..message, os.date("%H:%M:%S", time), category, string.upper(Enum.LogPriority[priority]), ...)
end

function Log.GetWriter()
	return currentWriter
end

function Log.SetWriter(writer)
	currentWriter = writer
end

function Log.Log(category, priority, message, ...)
	if currentWriter and priority >= currentPriority then
		currentWriter(category, priority, message, ...)
	end
end

function Log.Trace(category, message, ...) Log.Log(category, Enum.LogPriority.Trace, message, ...) end
function Log.Verbose(category, message, ...) Log.Log(category, Enum.LogPriority.Verbose, message, ...) end
function Log.Debug(category, message, ...) Log.Log(category, Enum.LogPriority.Debug, message, ...) end
function Log.Info(category, message, ...) Log.Log(category, Enum.LogPriority.Info, message, ...) end
function Log.Warn(category, message, ...) Log.Log(category, Enum.LogPriority.Warn, message, ...) end
function Log.Error(category, message, ...) Log.Log(category, Enum.LogPriority.Error, message, ...) end
function Log.Critical(category, message, ...) Log.Log(category, Enum.LogPriority.Critical, message, ...) end

return Log