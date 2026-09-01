package main

import (
	"log"
	"net/http"
	"os"

	"hermes/server/db"
	"hermes/server/handlers"
)

func main() {
	// Initialize database
	if err := db.Init("hermes.db"); err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Set up HTTP routes
	mux := http.NewServeMux()

	// Agent endpoints
	mux.HandleFunc("/register", handlers.RegisterHandler)
	mux.HandleFunc("/heartbeat", handlers.HeartbeatHandler)
	mux.HandleFunc("/result", handlers.ResultHandler)

	// API endpoints
	mux.HandleFunc("/api/agents", handlers.AgentsHandler)
	mux.HandleFunc("/api/tasks/create", handlers.TaskCreateHandler)

	// Serve web dashboard
	fs := http.FileServer(http.Dir("web"))
	mux.Handle("/", fs)

	// Start server (TLS optional; for now plain HTTP on 443? Use 8080 for dev)
	addr := ":8080"
	if os.Getenv("PORT") != "" {
		addr = ":" + os.Getenv("PORT")
	}
	log.Printf("Hermes server listening on %s", addr)
	log.Fatal(http.ListenAndServe(addr, mux))
}
