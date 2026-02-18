#!/usr/bin/env python3

import sys
import json
import urllib.request
import configparser


class VaultConfig:
    def __init__(self, config_path: str):
        self.config = configparser.ConfigParser()
        self.config.read(config_path)

        try:
            self.address = self.config["vault"]["address"]
            self.username = self.config["vault"]["username"]
            self.password = self.config["vault"]["password"]
            self.mount = self.config["vault"].get("mount", "secret")
        except KeyError:
            raise ValueError("Invalid INI configuration")


class VaultClient:
    def __init__(self, config: VaultConfig):
        self.address = config.address
        self.username = config.username
        self.password = config.password
        self.mount = config.mount
        self.token = None

    def login(self):
        url = f"{self.address}/v1/auth/userpass/login/{self.username}"
        payload = json.dumps({"password": self.password}).encode()

        request = urllib.request.Request(url, data=payload, method="POST")
        request.add_header("Content-Type", "application/json")

        with urllib.request.urlopen(request) as response:
            data = json.loads(response.read().decode())
            self.token = data["auth"]["client_token"]

    def read_kv_v2(self, profile: str) -> dict:
        url = f"{self.address}/v1/{self.mount}/data/aws/{profile}"
        request = urllib.request.Request(url)
        request.add_header("X-Vault-Token", self.token)

        with urllib.request.urlopen(request) as response:
            data = json.loads(response.read().decode())
            return data["data"]["data"]

    def revoke_token(self):
        if not self.token:
            return

        url = f"{self.address}/v1/auth/token/revoke-self"
        request = urllib.request.Request(url, method="POST")
        request.add_header("X-Vault-Token", self.token)

        try:
            urllib.request.urlopen(request)
        except:
            pass  # On n'échoue pas si revoke échoue


class AwsCredentialFormatter:
    @staticmethod
    def format(credentials: dict) -> str:
        output = {
            "Version": 1,
            "AccessKeyId": credentials["aws_access_key_id"],
            "SecretAccessKey": credentials["aws_secret_access_key"]
        }

        if "aws_session_token" in credentials:
            output["SessionToken"] = credentials["aws_session_token"]

        return json.dumps(output)


def main():
    if len(sys.argv) < 2:
        print("Profile argument missing", file=sys.stderr)
        sys.exit(1)

    profile = sys.argv[1]

    try:
        config = VaultConfig("/etc/vault-aws.ini")
        client = VaultClient(config)

        client.login()
        credentials = client.read_kv_v2(profile)
        client.revoke_token()

        print(AwsCredentialFormatter.format(credentials))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
