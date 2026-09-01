package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/google/uuid"

	"hermes/server/api"
	"hermes/server/db"
)

// TaskCreateHandler handles POST /api/tasks/create
func TaskCreateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		AgentID   string   `json:"agent_id"`
		Plugin    string   `json:"plugin"`
		Arguments []string `json:"arguments"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Validate plugin name (allowlist)
	validPlugins := map[string]bool{
		"example":       true,
		"system_info":   true,
		"file_integrity": true,
		"network_scanner": true,
	}
	if !validPlugins[req.Plugin] {
		http.Error(w, "Invalid plugin name", http.StatusBadRequest)
		return
	}

	// Check agent exists
	if _, err := db.GetAgent(req.AgentID); err != nil {
		http.Error(w, "Agent not found", http.StatusNotFound)
		return
	}

	// Create task
	task := &db.Task{
		ID:        uuid.New().String(),
		AgentID:   req.AgentID,
		Plugin:    req.Plugin,
		Arguments: req.Arguments,
		Status:    "pending",
		CreatedAt: time.Now().Unix(),
	}

	// Save to DB
	if err := db.SaveTask(task); err != nil {
		http.Error(w, "Failed to save task", http.StatusInternalServerError)
		return
	}

	// Add to queue
	api.TaskQueue.AddTask(req.AgentID, task)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"task_id": task.ID,
		"status":  "queued",
	})
}
