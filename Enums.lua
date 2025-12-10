Enum.LogCategory = Enum.Create({
    App = 1,
	Video = 2,
	UserInterface = 3,
	Network = 4,
	Build = 5
})

Enum.LogPriority = Enum.Create({
    Trace = 1,
    Verbose = 2,
    Debug = 3,
    Info = 4,
    Warn = 5,
    Error = 6,
    Critical = 7
})

Enum.PathType = Enum.Create({
    File = 1,
    Folder = 2
})

Enum.HorizontalAlignment = Enum.Create({
	Left = 1,
	Middle = 2,
	Right = 3
})

Enum.VerticalAlignment = Enum.Create({
	Top = 1,
	Middle = 2,
	Bottom = 3
})

Enum.InputType = Enum.Create({
	Keyboard = 1,
	Mouse = 2
})

Enum.PathType = Enum.Create({
    File = 1,
    Folder = 2
})

Enum.ExecutionMode = Enum.Create({
	Read = "r",
	Write = "w",
	Execute = "e"
})

Enum.OptionDataType = Enum.Create({
	String = 1,
	Boolean = 2,
	Number = 3,
	Enum = 4,
	Path = 5
})