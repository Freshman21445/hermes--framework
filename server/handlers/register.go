package handlers

import (
	"crypto/rand"
	"encoding/json"
	"net/http"

	"github.com/google/uuid"

	"hermes/server/db"
)

// RegisterHandler handles POST /register
func RegisterHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		Hostname      string `json:"hostname"`
		OS            string `json:"os"`
		KernelVersion string `json:"kernel_version"`
		IP            string `json:"ip"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Generate agent ID and session key
	agentID := uuid.New().String()
	sessionKey := make([]byte, 32)
	if _, err := rand.Read(sessionKey); err != nil {
		http.Error(w, "Internal error", http.StatusInternalServerError)
		return
	}

	// Store agent
	agent := &db.Agent{
		ID:         agentID,
		IP:         req.IP,
		Hostname:   req.Hostname,
		OS:         req.OS,
		Kernel:     req.KernelVersion,
		LastSeen:   0,
		Status:     "online",
		SessionKey: sessionKey,
	}
	if err := db.SaveAgent(agent); err != nil {
		http.Error(w, "Failed to save agent", http.StatusInternalServerError)
		return
	}

	// Respond
	resp := map[string]string{
		"agent_id":    agentID,
		"session_key": string(sessionKey), // In production, base64 encode
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}
