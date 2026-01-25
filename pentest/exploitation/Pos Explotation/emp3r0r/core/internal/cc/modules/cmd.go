package modules

type CmdSenderFunc func(string, string, string) error

// how to send command to agents, will be injected with actual funtion
var CmdSender CmdSenderFunc
