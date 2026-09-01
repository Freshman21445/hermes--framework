package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"hermes/server/db"
	"hermes/server/handlers"
)

func TestEndToEnd(t *testing.T) {
	// Initialize in-memory DB for testing
	db.Init(":memory:")
	defer db.Close()

	// Create test server
	mux := http.NewServeMux()
	mux.HandleFunc("/register", handlers.RegisterHandler)
	mux.HandleFunc("/heartbeat", handlers.HeartbeatHandler)
	mux.HandleFunc("/result", handlers.ResultHandler)
	mux.HandleFunc("/api/tasks/create", handlers.TaskCreateHandler)
	ts := httptest.NewServer(mux)
	defer ts.Close()

	// 1. Register agent
	regBody := `{"hostname":"test","os":"linux","kernel_version":"5.10","ip":"127.0.0.1"}`
	resp, err := http.Post(ts.URL+"/register", "application/json", bytes.NewBufferString(regBody))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	var regResp map[string]string
	json.NewDecoder(resp.Body).Decode(&regResp)
	agentID := regResp["agent_id"]
	if agentID == "" {
		t.Fatal("No agent ID")
	}

	// 2. Create task for agent
	taskBody := `{"agent_id":"` + agentID + `","plugin":"system_info","arguments":[]}`
	resp, err = http.Post(ts.URL+"/api/tasks/create", "application/json", bytes.NewBufferString(taskBody))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	// 3. Heartbeat to receive task
	hbBody := `{"agent_id":"` + agentID + `","timestamp":123,"status":"alive"}`
	resp, err = http.Post(ts.URL+"/heartbeat", "application/json", bytes.NewBufferString(hbBody))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	var hbResp map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&hbResp)
	if _, ok := hbResp["task"]; !ok {
		t.Fatal("No task returned")
	}

	// 4. Submit result
	resBody := `{"task_id":"test-task","success":true,"output":"ok"}`
	resp, err = http.Post(ts.URL+"/result", "application/json", bytes.NewBufferString(resBody))
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
}
