import socket
import time
from ansible.module_utils.basic import *


def check_ip(params):
	server_address = params["ip_address"]
	server_port = params["port"]

	s = socket.socket()
	print "Attempting to connect to {} on port {}".format(server_address, server_port)
	try:
		s.connect((server_address, server_port))
		response = "Connected to {} on port {}".format(server_address, server_port)


	except socket.error, e:
		response = "Connection to {} on port {} failed".format(server_address, server_port)

	finally:
		s.close()

	has_changed = False
	meta = {"result": "{}".format(response)}
	return (has_changed, meta)


def main():
	fields = {
		"state": {"required": True, "type": "str"},
		"ip_address": {"required": True, "type": "str"},
		"port": {"required": True, "type": "int"},
	}

	choice_map = {
		"check_connection": check_ip,
	}
	module = AnsibleModule(argument_spec=fields)
	has_changed, result = choice_map.get(module.params['state'])(module.params)
	module.exit_json(changed=has_changed, meta=result)


if __name__ == '__main__':
	main()
