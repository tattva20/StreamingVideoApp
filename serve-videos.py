#!/usr/bin/env python3
"""
Simple HTTP server to serve videos.json for testing RemoteVideoLoader.

Usage:
    python3 serve-videos.py

Then the videos will be available at: http://localhost:8000/videos.json
"""

import http.server
import socketserver
import os

PORT = 8000

# Change to the directory containing videos.json
os.chdir(os.path.dirname(os.path.abspath(__file__)))

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        return super().end_headers()

    def do_GET(self):
        if self.path == '/':
            self.path = '/videos.json'
        return super().do_GET()

Handler = CORSRequestHandler

print(f"Starting HTTP server on port {PORT}...")
print(f"Videos JSON available at: http://localhost:{PORT}/videos.json")
print("Press Ctrl+C to stop the server")

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    httpd.serve_forever()
