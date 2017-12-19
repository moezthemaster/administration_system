#!/usr/bin/python

DOCUMENTATION = '''  
---
module: github_repo  
short_description: Manage your repos on Github  
'''

EXAMPLES = '''  
- name: Create a github Repo
  github_repo:
    github_auth_key: "..."
    name: "Hello-World"
    description: "This is your first repository"
    private: yes
    has_issues: no
    has_wiki: no
    has_downloads: no
  register: result

- name: Delete that repo 
  github_repo:
    github_auth_key: "..."
    name: "Hello-World"
    state: absent
  register: result
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
