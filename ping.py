import socket
import sys


class IpChecker:
	def __init__(self, address, port):
		self.address = address
		self.port = port

	def check_server(self):
		# create a TCP socket
		s = socket.socket()
		print "Attempting to connect to {} on port {}".format(self.address, self.port)
		try:
			s.connect((self.address, self.port))
			print "Connected to {} on port {}".format(self.address, self.port)
			return True
		except socket.error, e:
			print "Connection to {} on port {} failed".format(self.address, self.port)
			return False, e
		finally:
			s.close()
# call example
server = '192.168.1.131'
port = 8080
check = IpChecker(server, port)
check.check_server()

