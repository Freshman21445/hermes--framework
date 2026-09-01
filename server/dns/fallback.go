package dns

import (
	"fmt"
	"net"
	"strings"
)

// StartDNSServer starts a UDP DNS server on port 53.
func StartDNSServer() error {
	addr := net.UDPAddr{Port: 53, IP: net.ParseIP("0.0.0.0")}
	conn, err := net.ListenUDP("udp", &addr)
	if err != nil {
		return err
	}
	defer conn.Close()

	buf := make([]byte, 512)
	for {
		n, clientAddr, err := conn.ReadFromUDP(buf)
		if err != nil {
			continue
		}
		go handleDNSQuery(conn, clientAddr, buf[:n])
	}
}

func handleDNSQuery(conn *net.UDPConn, addr *net.UDPAddr, query []byte) {
	// Very simple: if the query contains "cmd.hermes.local", respond with a TXT record.
	// For proper DNS parsing, use a library like miekg/dns. Here we just check for substring.
	if strings.Contains(string(query), "cmd.hermes.local") {
		// Build a minimal DNS response with TXT record containing a sample command.
		// This is a stub; in production, use a DNS library.
		response := []byte{0x00, 0x01, 0x80, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00}
		// Echo query name, then answer.
		// Not a complete implementation; for demonstration only.
		conn.WriteToUDP(response, addr)
	}
}
