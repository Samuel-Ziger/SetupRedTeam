//go:build !linux
// +build !linux

package main

// conditionalC2FailNotify is a no-op on non-Linux platforms.
func conditionalC2FailNotify() {}
