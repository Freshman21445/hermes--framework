package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"hermes/server/db"
)

// AgentsHandler handles GET /api/agents
func AgentsHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	agents, err := db.GetAllAgents()
	if err != nil {
		http.Error(w, "Failed to retrieve agents", http.StatusInternalServerError)
		return
	}

	// Calculate online status (last seen within 5 minutes)
	now := time.Now().Unix()
	for _, agent := range agents {
		if now-agent.LastSeen <= 300 {
			agent.Status = "online"
		} else {
			agent.Status = "offline"
		}
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(agents)
}
