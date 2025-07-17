// DOM Elements
const terminal = document.getElementById('terminal');
const datetimeDisplay = document.getElementById('datetime');
const startBtn = document.getElementById('startBtn');
const stopBtn = document.getElementById('stopBtn');
const phoneInput = document.getElementById('phone');

// State
let attackActive = false;
let requestCount = 0;
const API_BASE = `http://${window.location.host}/api/v1`;

// Update datetime every second
function updateDateTime() {
    const now = new Date();
    datetimeDisplay.textContent = now.toLocaleString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}
setInterval(updateDateTime, 1000);
updateDateTime();

// Log messages to terminal
function log(message) {
    const now = new Date();
    const timestamp = now.toLocaleTimeString();
    terminal.innerHTML += `[${timestamp}] ${message}<br>`;
    terminal.scrollTop = terminal.scrollHeight;
}

// Connect to server events
function connectToServer() {
    const eventSource = new EventSource(`${API_BASE}/events`);
    
    eventSource.onmessage = (event) => {
        const data = JSON.parse(event.data);
        log(data.message);
    };
    
    eventSource.onerror = () => {
        log("Connection to server lost. Reconnecting...");
        setTimeout(connectToServer, 3000);
    };
}

// Start attack
async function startTurbo() {
    if(attackActive) return;
    
    const phone = phoneInput.value.trim();
    if(!phone) {
        log("Error: Please enter target number");
        return;
    }

    try {
        const response = await fetch(`${API_BASE}/start`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ phone })
        });
        
        const data = await response.json();
        
        if(data.status === "success") {
            attackActive = true;
            requestCount = 0;
            log(`🚀 Turbo attack initiated against: ${phone}`);
        } else {
            log(`Error: ${data.message}`);
        }
    } catch(err) {
        log(`Connection error: ${err.message}`);
    }
}

// Stop attack
async function stopSending() {
    if(!attackActive) return;
    
    const phone = phoneInput.value.trim();
    try {
        const response = await fetch(`${API_BASE}/stop?phone=${encodeURIComponent(phone)}`);
        const data = await response.json();
        
        if(data.status === "success") {
            attackActive = false;
            log(`🛑 Attack stopped. Total requests: ${requestCount}`);
        } else {
            log(`Error: ${data.message}`);
        }
    } catch(err) {
        log(`Connection error: ${err.message}`);
    }
}

// Event listeners
startBtn.addEventListener('click', startTurbo);
stopBtn.addEventListener('click', stopSending);

// Initialize
log("System initialized. Ready for turbo attack.");
connectToServer();
