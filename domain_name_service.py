#!/usr/bin/env python

import socket
import sys

class DnsResolver:
	def __init__(self, dns_host, dns_ip_address, dns_port):
		self.dns_host = dns_host
		self.dns_ip_address = dns_ip_address
		self.dns_port = dns_port

	def nslookup(self):
		"""
		:return: couple host ip adress with requested port 
		"""
		try:
			result = socket.getaddrinfo(self.dns_host, self.dns_port)
		except socket.timeout:
			print "connection time out"
			sys.exit(1)
		except socket.gaierror:
			print "connection to {} failed. please verify your host or contact " \
			      "support.".format(self.dns_host)
			sys.exit(1)
		count = 1
		a = []
		for item in result:
			r = "couple (ip/port) {}: {}".format(count, item[4])
			a.append(r)
			count += 1
		return a

	def reverse_lookup(self):
		"""
		:return: primary hostname dns of requested ip address
		"""
		try:
			result = socket.gethostbyaddr(self.dns_ip_address)
			r = result[0]
			hostname = "primary hostname for {} is: {}".format(self.dns_ip_address, r)
		except socket.herror:
			print "oups, error"
			sys.exit(1)
		return hostname


#test class call
host = 'www.google.fr'
ip = '8.8.8.8'
port = 0

address = DnsResolver(host, ip, port)
print address.reverse_lookup()

print address.nslookup()