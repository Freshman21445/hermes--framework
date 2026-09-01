// Fetch and render agents
async function fetchAgents() {
    try {
        const res = await fetch('/api/agents');
        const agents = await res.json();
        renderAgents(agents);
    } catch (err) {
        console.error('Failed to fetch agents:', err);
    }
}

function renderAgents(agents) {
    const tbody = document.querySelector('#agents-table tbody');
    tbody.innerHTML = '';
    agents.forEach(agent => {
        const statusEmoji = agent.status === 'online' ? '🟢' : agent.status === 'offline' ? '🔴' : '🟡';
        const lastSeen = new Date(agent.last_seen * 1000).toLocaleString();
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${statusEmoji}</td>
            <td>${agent.id}</td>
            <td>${agent.hostname}</td>
            <td>${agent.ip}</td>
            <td>${agent.os}</td>
            <td>${lastSeen}</td>
            <td><button onclick="fillAgentId('${agent.id}')">Use</button></td>
        `;
        tbody.appendChild(row);
    });
}

function fillAgentId(id) {
    document.getElementById('agent-id').value = id;
}

// Handle task form submission
document.getElementById('task-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    const agent_id = document.getElementById('agent-id').value;
    const plugin = document.getElementById('plugin-select').value;
    const argsStr = document.getElementById('plugin-args').value;
    const arguments = argsStr ? argsStr.split(',').map(s => s.trim()) : [];

    try {
        const res = await fetch('/api/tasks/create', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ agent_id, plugin, arguments })
        });
        const data = await res.json();
        alert(`Task created: ${data.task_id}`);
    } catch (err) {
        console.error('Task creation failed:', err);
    }
});

// Poll every 5 seconds
setInterval(fetchAgents, 5000);
fetchAgents();
