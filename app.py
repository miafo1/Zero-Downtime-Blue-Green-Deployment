import os
import socket
import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)

# Load configuration from environment variables
APP_VERSION = os.getenv('APP_VERSION', '1.0')
APP_COLOR = os.getenv('APP_COLOR', 'blue')
HOSTNAME = socket.gethostname()

# Database Config
DB_HOST = os.getenv('DB_HOST', 'db')
DB_NAME = os.getenv('DB_NAME', 'postgres')
DB_USER = os.getenv('DB_USER', 'postgres')
DB_PASS = os.getenv('DB_PASS', 'postgres')

def get_db_connection():
    conn = psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )
    return conn

def init_db():
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute('CREATE TABLE IF NOT EXISTS visits (id SERIAL PRIMARY KEY, count INTEGER DEFAULT 0);')
        # Initialize count if table is empty
        cur.execute('SELECT count(*) FROM visits;')
        if cur.fetchone()[0] == 0:
            cur.execute('INSERT INTO visits (count) VALUES (0);')
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"DB Init Error: {e}")

# Initialize DB on startup (simple approach for demo)
init_db()

@app.route('/')
def hello():
    visit_count = 0
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        # Atomic increment
        cur.execute('UPDATE visits SET count = count + 1 WHERE id = 1 RETURNING count;')
        visit_count = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        visit_count = f"Error: {e}"

    return jsonify({
        'message': 'Hello from Zero-Downtime App!',
        'version': APP_VERSION,
        'color': APP_COLOR,
        'hostname': HOSTNAME,
        'db_status': 'connected',
        'visit_count': visit_count
    })

@app.route('/health')
def health():
    # Check DB connection
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({'status': 'healthy', 'db': 'ok'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'db': str(e)}), 500

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
