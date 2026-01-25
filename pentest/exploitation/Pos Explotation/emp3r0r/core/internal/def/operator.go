package def

// Operation is a command or module operation to be executed on C2 server
type Operation struct {
	AgentTag   string  `json:"agent_tag"`   // the target agent
	Action     string  `json:"action"`      // the action to perform: "command" or "module"
	Command    *string `json:"command"`     // the command to send to the agent (if action is "command")
	CommandID  *string `json:"command_id"`  // the command ID (if action is "command")
	ModuleName *string `json:"module_name"` // the module (if action is "module")
	SetOption  *string `json:"set_option"`  // the option to set (if action is "module")
	SetValue   *string `json:"set_value"`   // the value to set (if action is "module")
}

// IsOptionSet checks if a specific option is set
func (op *Operation) IsOptionSet(option string) bool {
	switch option {
	case "command":
		return op.Command != nil
	case "command_id":
		return op.CommandID != nil
	case "module_name":
		return op.ModuleName != nil
	case "set_option":
		return op.SetOption != nil
	case "set_value":
		return op.SetValue != nil
	default:
		return false
	}
}
