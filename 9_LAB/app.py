from http.server import BaseHTTPRequestHandler, HTTPServer

class HelloHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(b'Hello, World!')

def run_server():
    server_address = ('', 8080)
    httpd = HTTPServer(server_address, HelloHandler)
    print('Uruchamiam serwer HTTP na porcie 8080...')
    print('Dodalem linijke -- wersja 2')
    httpd.serve_forever()

if __name__ == '__main__':
    run_server()
