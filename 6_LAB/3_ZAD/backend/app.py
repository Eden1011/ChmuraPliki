from flask import Flask, jsonify
import psycopg2
import socket
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        'service': 'backend',
        'status': 'running'
    })

@app.route('/check-database')
def check_database():
    try:
        conn = psycopg2.connect(
            host="database",
            database="testdb",
            user="postgres",
            password="postgres"
        )
        conn.close()
        return jsonify({
            'database_connection': 'successful'
        })
    except Exception as e:
        return jsonify({
            'database_connection': 'failed',
            'error': str(e)
        }), 500

@app.route('/network-info')
def network_info():
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    return jsonify({
        'hostname': hostname,
        'local_ip': local_ip,
        'database_hostname_resolves': check_hostname_resolves('database'),
        'frontend_hostname_resolves': check_hostname_resolves('frontend')
    })

def check_hostname_resolves(hostname):
    try:
        socket.gethostbyname(hostname)
        return True
    except socket.error:
        return False

if __name__ == '__main__':
    app.run(host='0.0.0.0')
