#!/usr/bin/env python3
import os
import sys
import subprocess
import shutil

def install_server():
    if not os.path.exists("server/hermes-server"):
        print("Server binary not found. Build it first.")
        sys.exit(1)
    shutil.copy("server/hermes-server", "/usr/local/bin/hermes-server")
    # Create systemd service
    with open("/etc/systemd/system/hermes-server.service", "w") as f:
        f.write("""
[Unit]
Description=Hermes C2 Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hermes-server
Restart=always

[Install]
WantedBy=multi-user.target
""")
    subprocess.run(["systemctl", "enable", "hermes-server"])
    subprocess.run(["systemctl", "start", "hermes-server"])
    print("Server installed and started.")

def install_agent():
    if not os.path.exists("zig-out/bin/hermes"):
        print("Agent binary not found. Build it first.")
        sys.exit(1)
    shutil.copy("zig-out/bin/hermes", "/usr/local/bin/hermes")
    with open("/etc/systemd/system/hermes-agent.service", "w") as f:
        f.write("""
[Unit]
Description=Hermes Agent
After=network.target

[Service]
ExecStart=/usr/local/bin/hermes
Restart=always

[Install]
WantedBy=multi-user.target
""")
    subprocess.run(["systemctl", "enable", "hermes-agent"])
    subprocess.run(["systemctl", "start", "hermes-agent"])
    print("Agent installed and started.")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: install.py [server|agent]")
        sys.exit(1)
    target = sys.argv[1]
    if target == "server":
        install_server()
    elif target == "agent":
        install_agent()
    else:
        print("Invalid argument. Use 'server' or 'agent'.")
        sys.exit(1)
