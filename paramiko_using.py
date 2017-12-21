import paramiko
import socket

hostname = '192.168.1.130'
username = 'e'
key = "/home/vagrant/.ssh/id_rsa"
command = "ls -ltar"

port = 22

try:
	client = paramiko.SSHClient()
	client.load_system_host_keys()
	client.set_missing_host_key_policy(paramiko.WarningPolicy())
	paramiko.util.log_to_file('paramiko.log')
	client.connect(hostname, port=port, username=username, key_filename=key, timeout=10)

	stdin, stdout, stderr = client.exec_command(command)
	print stdout.read(), stderr.read()

except paramiko.AuthenticationException:
	print "Authentification to {} on port {} refused. Please check your credentials or contact support".format(hostname, port)
except socket.timeout:
	print "Timout. Please check your hostname or contact support"
except IOError:
	print " Your file {} does not exist or is not readable. please check it or contact support".format(key)
finally:
	client.close()