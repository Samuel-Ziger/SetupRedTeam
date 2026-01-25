//go:build !linux
// +build !linux

package external_file

// ExtractBashRC extract embedded bashrc and configure our bash shell
func ExtractBashRC(bash, bashrc string) error {
	return nil
}
