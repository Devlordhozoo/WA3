clear
#!/bin/bash

# WhatsApp Turbo Server PRO+
# Handles backend operations and API endpoints

# Configuration
PORT=8080
LOG_FILE="/tmp/turbo_server.log"
API_PREFIX="/api/v1"

# Colors for terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Start the server
start_server() {
    echo -e "${GREEN}[+]${NC} Starting WhatsApp Turbo Server on port ${YELLOW}$PORT${NC}"
    echo -e "${GREEN}[+]${NC} API endpoints available under ${YELLOW}$API_PREFIX${NC}"
    echo -e "${GREEN}[+]${NC} Log file: ${YELLOW}$LOG_FILE${NC}"

    # Create Python server with API endpoints
    cat <<EOF > server.py
from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import time
import threading
from urllib.parse import urlparse, parse_qs

HOST = "0.0.0.0"
PORT = $PORT
API_PREFIX = "$API_PREFIX"
running_attacks = {}

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            self.send_response(301)
            self.send_header("Location", "/index.html")
            self.end_headers()
        elif self.path.endswith(".js") or self.path.endswith(".css") or self.path.endswith(".html"):
            self.serve_static_file()
        elif self.path.startswith(API_PREFIX):
            self.handle_api_request()
        else:
            self.send_error(404)

    def do_POST(self):
        if self.path.startswith(API_PREFIX):
            self.handle_api_request()
        else:
            self.send_error(404)

    def serve_static_file(self):
        try:
            with open('.' + self.path, 'rb') as file:
                self.send_response(200)
                if self.path.endswith(".js"):
                    self.send_header("Content-type", "application/javascript")
                elif self.path.endswith(".css"):
                    self.send_header("Content-type", "text/css")
                else:
                    self.send_header("Content-type", "text/html")
                self.end_headers()
                self.wfile.write(file.read())
        except:
            self.send_error(404)

    def handle_api_request(self):
        endpoint = self.path[len(API_PREFIX):]
        
        if endpoint == "/start":
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            
            phone = data.get('phone')
            if not phone:
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'{"status":"error","message":"Phone number required"}')
                return
            
            if phone in running_attacks:
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'{"status":"running","message":"Attack already running"}')
                return
            
            # Start attack in new thread
            running_attacks[phone] = True
            threading.Thread(target=self.run_attack, args=(phone,)).start()
            
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(b'{"status":"success","message":"Attack started"}')
            
        elif endpoint == "/stop":
            phone = parse_qs(urlparse(self.path).query.get('phone', [''])[0]
            if phone in running_attacks:
                running_attacks[phone] = False
                del running_attacks[phone]
                response = b'{"status":"success","message":"Attack stopped"}'
            else:
                response = b'{"status":"error","message":"No active attack"}'
            
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(response)
            
        elif endpoint == "/status":
            self.send_response(200)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "status": "running",
                "active_attacks": list(running_attacks.keys())
            }).encode())
            
        else:
            self.send_error(404)

    def run_attack(self, phone):
        log_message(f"Attack started for {phone}")
        while running_attacks.get(phone, False):
            # Simulate attack (replace with actual implementation)
            log_message(f"Sending message to {phone}")
            time.sleep(0.1)
        log_message(f"Attack stopped for {phone}")

def log_message(message):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"
    with open("$LOG_FILE", "a") as f:
        f.write(log_entry)
    print(log_entry, end='')

if __name__ == "__main__":
    server = HTTPServer((HOST, PORT), RequestHandler)
    print(f"Server started at http://{HOST}:{PORT}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    
    server.server_close()
    print("Server stopped.")
EOF

    python3 server.py
}

# Main execution
clear
echo -e "${RED}WhatsApp Turbo Server PRO+${NC}"
echo -e "${YELLOW}===========================${NC}"
start_server
