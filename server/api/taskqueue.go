package api

import (
	"sync"

	"hermes/server/db"
)

// TaskQueue is an in-memory FIFO queue per agent.
type TaskQueueType struct {
	mu    sync.Mutex
	queue map[string][]*db.Task
}

var TaskQueue = &TaskQueueType{
	queue: make(map[string][]*db.Task),
}

// AddTask adds a task to the queue for a specific agent.
func (q *TaskQueueType) AddTask(agentID string, task *db.Task) {
	q.mu.Lock()
	defer q.mu.Unlock()
	q.queue[agentID] = append(q.queue[agentID], task)
}

// GetTask pops the first pending task for an agent.
func (q *TaskQueueType) GetTask(agentID string) *db.Task {
	q.mu.Lock()
	defer q.mu.Unlock()
	tasks := q.queue[agentID]
	if len(tasks) == 0 {
		return nil
	}
	task := tasks[0]
	q.queue[agentID] = tasks[1:]
	return task
}
