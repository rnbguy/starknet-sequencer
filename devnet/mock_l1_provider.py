#!/usr/bin/env python3
"""
Simple mock L1 provider for devnet testing.
Responds to basic Ethereum JSON-RPC calls that apollo_node might make.
"""

import json
import socketserver
import http.server
import threading
import time
from urllib.parse import urlparse, parse_qs

class MockL1Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Reduce noise in logs
        pass
        
    def do_POST(self):
        try:
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length > 0:
                post_data = self.rfile.read(content_length)
                request = json.loads(post_data.decode('utf-8'))
            else:
                request = {}
            
            method = request.get('method', '')
            request_id = request.get('id', 1)
            
            # Mock responses for common Ethereum JSON-RPC methods
            response = {
                "jsonrpc": "2.0",
                "id": request_id,
                "result": None
            }
            
            if method == 'eth_chainId':
                response["result"] = "0x1"  # Mainnet
            elif method == 'eth_blockNumber':
                # Return increasing block number
                current_time = int(time.time())
                block_number = hex(current_time % 1000000)  # Simple incrementing
                response["result"] = block_number
            elif method == 'eth_getBlockByNumber':
                response["result"] = {
                    "number": "0x1",
                    "hash": "0x" + "0" * 64,
                    "parentHash": "0x" + "0" * 64,
                    "timestamp": hex(int(time.time())),
                    "gasLimit": "0x1c9c380",
                    "gasUsed": "0x0",
                    "transactions": []
                }
            elif method == 'eth_call':
                # Return empty result for contract calls
                response["result"] = "0x"
            elif method == 'eth_getLogs':
                # Return empty logs
                response["result"] = []
            elif method == 'net_version':
                response["result"] = "1"
            else:
                # Default response for unknown methods
                response["result"] = "0x0"
            
            # Send response
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        except Exception as e:
            # Send error response
            error_response = {
                "jsonrpc": "2.0",
                "id": 1,
                "error": {
                    "code": -32603,
                    "message": f"Internal error: {str(e)}"
                }
            }
            self.send_response(500)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_response).encode('utf-8'))

    def do_GET(self):
        # Health check endpoint
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "ok"}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def start_mock_l1_provider(port=8545):
    """Start the mock L1 provider on the specified port."""
    print(f"Starting mock L1 provider on port {port}")
    
    with socketserver.TCPServer(("", port), MockL1Handler) as httpd:
        print(f"Mock L1 provider running at http://localhost:{port}")
        print("Serving forever...")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down mock L1 provider")

if __name__ == "__main__":
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8545
    start_mock_l1_provider(port)