package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"hermes/server/api"
	"hermes/server/db"
)

// HeartbeatHandler handles POST /heartbeat
func HeartbeatHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		AgentID   string `json:"agent_id"`
		Timestamp int64  `json:"timestamp"`
		Status    string `json:"status"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Update agent last seen
	agent, err := db.GetAgent(req.AgentID)
	if err != nil || agent == nil {
		http.Error(w, "Agent not found", http.StatusNotFound)
		return
	}
	agent.LastSeen = time.Now().Unix()
	agent.Status = "online"
	if err := db.SaveAgent(agent); err != nil {
		http.Error(w, "Failed to update agent", http.StatusInternalServerError)
		return
	}

	// Check task queue for this agent
	task := api.TaskQueue.GetTask(req.AgentID)
	if task != nil {
		// Mark task as running
		task.Status = "running"
		db.SaveTask(task)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"task": task,
		})
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "no_task"})
}

// ResultHandler handles POST /result
func ResultHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req struct {
		TaskID  string `json:"task_id"`
		Success bool   `json:"success"`
		Output  string `json:"output"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Save result
	result := &db.Result{
		TaskID:    req.TaskID,
		Success:   req.Success,
		Output:    req.Output,
		Timestamp: time.Now().Unix(),
	}
	if err := db.SaveResult(result); err != nil {
		http.Error(w, "Failed to save result", http.StatusInternalServerError)
		return
	}

	// Update task status
	if task, err := db.GetTask(req.TaskID); err == nil && task != nil {
		task.Status = "completed"
		if !req.Success {
			task.Status = "failed"
		}
		task.Result = req.Output
		db.SaveTask(task)
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}
