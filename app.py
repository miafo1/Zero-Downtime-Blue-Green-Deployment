import os
import socket
from flask import Flask, jsonify

app = Flask(__name__)

# Load configuration from environment variables
APP_VERSION = os.getenv('APP_VERSION', '1.0')
APP_COLOR = os.getenv('APP_COLOR', 'blue')  # Default to blue
HOSTNAME = socket.gethostname()

@app.route('/')
def hello():
    return jsonify({
        'message': 'Hello from Zero-Downtime App!',
        'version': APP_VERSION,
        'color': APP_COLOR,
        'hostname': HOSTNAME
    })

@app.route('/health')
def health():
    # In a real app, this might check DB connection, etc.
    return jsonify({'status': 'healthy'}), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
