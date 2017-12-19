import socket
from ansible.module_utils.basic import *


def check_ip(params):
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
		is_error = False
	except socket.error:
		response = "Connection to {} on port {} failed".format(server_address, server_port)
		status_code = 444
		is_error = True
	finally:
		s.close()

	has_changed = False
	meta = {"result": "{}".format(response)}
	return has_changed, meta, is_error

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
		"check_connection": check_ip,
	}
	module = AnsibleModule(argument_spec=fields)
	is_error, has_changed, result = choice_map.get(
		module.params['state'])(module.params)
	if not is_error:
		module.exit_json(changed=has_changed, meta=result)
	else:
		module.fail_json(msg="Error on module", meta=result)

if __name__ == '__main__':
	main()
