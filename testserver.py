import http.server

class MyHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        http.server.SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    http.server.test(HandlerClass=MyHTTPRequestHandler)
