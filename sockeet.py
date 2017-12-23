# import socket
# import sys
#
# url = 'www.eniededed.fr'
# port = 443
#
# print "socket creation..."
# s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# s.settimeout(5)
# print "socket build successful"
# print "connection to remote hote"
#
# try:
#	s.connect((url, port))
#	print "connected to {} on port {} succeeded.".format(url, port)
# except socket.timeout:
#	print "connection to {} on {} port timeout.".format(url, port)
#	sys.exit(1)
# except socket.gaierror, e:
#	print "{} not found. please check your url.".format(url)
#	sys.exit(1)
# try:
#	s.send('GET /index.html HTML/1.0\r \n\r\n')
#	while True:
#		data = s.recv(128)
#		print data
#		if data == "":
#			break
#
# except socket.timeout:
#	print "connection timeout. please check your data"
# finally:
#	s.close()

# !/usr/bin/env python
# --*--coding:UTF-8 --*--

# import socket, sys
#
# host = sys.argv[1]
# textport = sys.argv[2]
# s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
# try:
#	port = int(textport)
# except ValueError:
#	port = socket.getservbyname(textport,"udp")
#	s.connect((host, port))
#	print "entrez les donnees a transmettre"
#	data = sys.stdin.readline().strip()
#	s.sendall(data)
#	print "attente de reponse, Ctrl-C pour arreter"
#	while 1:
#		buf = s.recv(2048)
#		if not len(buf):
#			break
#		print buf

# !/usr/bin/env python
# --*-- coding:UTF-8 --*--

import socket

host = "ftp.ibiblio.org"
port = 21


def fini():
	data = s.recv(1024)
	print data
	if data == "":
		pass


s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, port))
fini()
s.send("USER anonymous\r\n")
fini()
s.send("PASS toto@tata.fr\r\n")
fini()
s.send("HELP\r\n")
fini()
s.send("QUIT\r\n")
s.close()
