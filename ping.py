import socket
import re
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

check = IpChecker('192.168.1.130', 80)
check.check_server()

# if __name__ == '__main__':
#	from optparse import OptionParser
#
#	parser = OptionParser()
#	parser.add_option("-a", "--address", dest="address", default="localhost", help="ADDRESS for server",
#	                  metavar="ADDRESS")
#	parser.add_option("-p", "--port", dest="port", type="int", default=80, help="PORT for server", metavar="PORT")
#	(options, args) = parser.parse_args()
#	print "options: {}, args: {}".format(options, args)
#	check = check_server(options.address, options.port)
#	print "check_server returned {}".format(check)
#	sys.exit(not check)
#
