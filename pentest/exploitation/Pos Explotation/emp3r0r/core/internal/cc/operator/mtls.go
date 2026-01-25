package operator

import (
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"os"
	"time"

	"github.com/jm33-m0/emp3r0r/core/internal/transport"
	"golang.org/x/net/http2"
)

var (
	// OperatorHTTPClient is an HTTP/2 client for the mTLS C2 operator server
	OperatorHTTPClient *http.Client

	// OperatorRootURL is the root URL of the mTLS C2 operator server
	OperatorRootURL string
)

// createMTLSHttpClient connects to the mTLS server and returns an HTTP/2 client
func createMTLSHttpClient() (*http.Client, error) {
	// Load client certificate
	clientCert, err := tls.LoadX509KeyPair(transport.OperatorClientCrtFile, transport.OperatorClientKeyFile)
	if err != nil {
		return nil, err
	}

	// Load CA certificate for server verification, different from C2 TLS cert
	caCert, err := os.ReadFile(transport.OperatorCaCrtFile)
	if err != nil {
		return nil, err
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// Configure mTLS
	tlsConfig := &tls.Config{
		GetClientCertificate: func(*tls.CertificateRequestInfo) (*tls.Certificate, error) {
			return &clientCert, nil
		},
		RootCAs: caCertPool,
	}

	// Create HTTP/2 transport
	transport := &http2.Transport{
		TLSClientConfig: tlsConfig,
		ReadIdleTimeout: 10 * time.Second, // Send PING if idle for 10s
		PingTimeout:     5 * time.Second,  // Timeout if PING response not received in 5s
	}

	// Create HTTP client with timeout
	client := &http.Client{
		Transport: transport,
		Timeout:   30 * time.Second, // Overall request timeout
	}

	return client, nil
}
