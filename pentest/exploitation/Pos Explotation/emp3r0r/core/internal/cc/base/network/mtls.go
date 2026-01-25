package network

import (
	"context"
	"net/http"
)

var (
	MTLSServer       *http.Server
	MTLSServerCtx    context.Context
	MTLSServerCancel context.CancelFunc
)
