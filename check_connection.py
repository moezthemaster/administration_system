#!/usr/bin/python

DOCUMENTATION = '''  
---
module: check_connection  
short_description: Check connection to servers  
'''

EXAMPLES = '''  
- name: Check ssh connection to server
  check_connection:
    state: 'check_connection'
    ip_address: '192.168.1.130'
    port: 22
  register: result
- debug: var=result

'''
import socket
from ansible.module_utils.basic import *


def check_server_connection(params):
	"""
	
	:param params: 
	:return: 
	"""
	server_address = params["ip_address"]
	server_port = params["port"]
	s = socket.socket()
	s.settimeout(5)

	print "Attempting to connect to {} on port {}".format(server_address, server_port)
	try:
		s.connect((server_address, server_port))
		response = "Connected to {} on port {}".format(server_address, server_port)
		status_code = 200
		has_changed = True
	except socket.error:
		response = "Connection to {} on port {} failed".format(server_address, server_port)
		status_code = 444
		has_changed = False
	finally:
		s.close()

	meta = {"result": "{}".format(response), "code": "{}".format(status_code)}
	return has_changed, meta


def main():
	"""
	Ansible module entry point
	:return: 
	"""
	fields = {
		"state": {"required": True, "type": "str"},
		"ip_address": {"required": True, "type": "str"},
		"port": {"required": True, "type": "int"},
	}

	choice_map = {
		"check_connection": check_server_connection,
	}
	module = AnsibleModule(argument_spec=fields)
	has_changed, result = choice_map.get(module.params['state'])(module.params)
	module.exit_json(changed=has_changed, meta=result)


if __name__ == '__main__':
	main()
