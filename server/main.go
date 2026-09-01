package main

import (
	"log"
	"net/http"
	"os"

	"hermes/server/db"
	"hermes/server/handlers"
	"hermes/server/dns"
	"hermes/server/utils"
)

func main() {
	// Initialize logger
	utils.InitLogger("/var/log/hermes.log")
	defer func() {
		if utils.InfoLogger != nil {
			// close file if needed
		}
	}()

	// Initialize database
	if err := db.Init("hermes.db"); err != nil {
		utils.ErrorLogger.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Start DNS fallback server
	go dns.StartDNSServer()

	// Set up HTTP routes
	mux := http.NewServeMux()
	mux.HandleFunc("/register", handlers.RegisterHandler)
	mux.HandleFunc("/heartbeat", handlers.HeartbeatHandler)
	mux.HandleFunc("/result", handlers.ResultHandler)
	mux.HandleFunc("/ws", handlers.WebSocketHandler)
	mux.HandleFunc("/api/agents", handlers.AgentsHandler)
	mux.HandleFunc("/api/tasks/create", handlers.TaskCreateHandler)
	fs := http.FileServer(http.Dir("web"))
	mux.Handle("/", fs)

	// Apply middleware
	handler := SecurityHeadersMiddleware(RateLimitMiddleware(mux))

	addr := ":8080"
	if os.Getenv("PORT") != "" {
		addr = ":" + os.Getenv("PORT")
	}

	utils.InfoLogger.Printf("Hermes server listening on %s", addr)
	// Use TLS in production
	// log.Fatal(http.ListenAndServeTLS(addr, "cert.pem", "key.pem", handler))
	log.Fatal(http.ListenAndServe(addr, handler))
}
