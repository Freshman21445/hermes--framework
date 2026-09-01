package db

import (
	"encoding/json"
	"time"

	bolt "go.etcd.io/bbolt"
)

// Agent struct
type Agent struct {
	ID         string    `json:"id"`
	IP         string    `json:"ip"`
	Hostname   string    `json:"hostname"`
	OS         string    `json:"os"`
	Kernel     string    `json:"kernel"`
	LastSeen   int64     `json:"last_seen"`
	Status     string    `json:"status"` // online, offline
	SessionKey []byte    `json:"-"`
}

// Task struct
type Task struct {
	ID        string   `json:"task_id"`
	AgentID   string   `json:"agent_id"`
	Plugin    string   `json:"plugin"`
	Arguments []string `json:"arguments"`
	Status    string   `json:"status"` // pending, running, completed, failed
	Result    string   `json:"result,omitempty"`
	CreatedAt int64    `json:"created_at"`
}

// Result struct (stored in results bucket)
type Result struct {
	TaskID    string `json:"task_id"`
	Success   bool   `json:"success"`
	Output    string `json:"output"`
	Timestamp int64  `json:"timestamp"`
}

// SaveAgent stores an agent in the database.
func SaveAgent(a *Agent) error {
	return DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("agents"))
		data, err := json.Marshal(a)
		if err != nil {
			return err
		}
		return b.Put([]byte(a.ID), data)
	})
}

// GetAgent retrieves an agent by ID.
func GetAgent(id string) (*Agent, error) {
	var agent Agent
	err := DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("agents"))
		data := b.Get([]byte(id))
		if data == nil {
			return nil
		}
		return json.Unmarshal(data, &agent)
	})
	if err != nil || agent.ID == "" {
		return nil, err
	}
	return &agent, nil
}

// GetAllAgents returns all agents.
func GetAllAgents() ([]*Agent, error) {
	var agents []*Agent
	err := DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("agents"))
		return b.ForEach(func(k, v []byte) error {
			var a Agent
			if err := json.Unmarshal(v, &a); err != nil {
				return err
			}
			agents = append(agents, &a)
			return nil
		})
	})
	return agents, err
}

// SaveTask stores a task in the database.
func SaveTask(t *Task) error {
	return DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("tasks"))
		data, err := json.Marshal(t)
		if err != nil {
			return err
		}
		return b.Put([]byte(t.ID), data)
	})
}

// GetTask retrieves a task by ID.
func GetTask(id string) (*Task, error) {
	var task Task
	err := DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("tasks"))
		data := b.Get([]byte(id))
		if data == nil {
			return nil
		}
		return json.Unmarshal(data, &task)
	})
	if err != nil || task.ID == "" {
		return nil, err
	}
	return &task, nil
}

// SaveResult stores a task result.
func SaveResult(r *Result) error {
	return DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte("results"))
		data, err := json.Marshal(r)
		if err != nil {
			return err
		}
		return b.Put([]byte(r.TaskID), data)
	})
}
