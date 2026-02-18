#!/usr/bin/env python3
"""
vault_aws.py

Description:
    Retrieve AWS credentials stored in HashiCorp Vault (KV v2)
    using userpass authentication and output them in AWS
    credential_process JSON format.

Author:
    Ton Nom

Version:
    1.1.0

Requirements:
    - Python 3.6+
    - cryptography
    - VAULT_SECRET_KEY environment variable must be set

Configuration:
    Default config file: /etc/vault-aws.ini

Usage:
    vault_aws.py dev
    vault_aws.py prod --config /custom/path/vault.ini
"""

import sys
import os
import json
import urllib.request
import urllib.error
import argparse
import configparser
import logging
from cryptography.fernet import Fernet


__author__ = "Ton Nom"
__version__ = "1.1.0"


# --------------------------------------------------
# Logging configuration
# --------------------------------------------------

logger = logging.getLogger("vault_aws")


def setup_logging(debug=False):
    level = logging.DEBUG if debug else logging.WARNING

    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(name)s - %(message)s",
        stream=sys.stderr
    )


# --------------------------------------------------
# Vault Configuration
# --------------------------------------------------

class VaultConfig:
    def __init__(self, config_path):
        logger.debug("Loading configuration from %s", config_path)

        self.config = configparser.ConfigParser()

        if not self.config.read(config_path):
            raise ValueError("Configuration file not found: {}".format(config_path))

        try:
            self.address = self.config["vault"]["address"].rstrip("/")
            self.username = self.config["vault"]["username"]
            self.password_encrypted = self.config["vault"]["password_encrypted"]
            self.mount = self.config["vault"].get("mount", "secret")
        except KeyError:
            raise ValueError("Invalid INI configuration")

        secret_key = os.environ.get("VAULT_SECRET_KEY")
        if not secret_key:
            raise ValueError("VAULT_SECRET_KEY not set")

        try:
            fernet = Fernet(secret_key.encode())
            self.password = fernet.decrypt(
                self.password_encrypted.encode()
            ).decode()
            logger.debug("Vault password successfully decrypted")
        except Exception:
            raise ValueError("Failed to decrypt Vault password")


# --------------------------------------------------
# Vault Client
# --------------------------------------------------

class VaultClient:
    def __init__(self, config):
        self.address = config.address
        self.username = config.username
        self.password = config.password
        self.mount = config.mount
        self.token = None

    def login(self):
        logger.debug("Authenticating to Vault at %s", self.address)

        url = "{}/v1/auth/userpass/login/{}".format(
            self.address, self.username
        )

        payload = json.dumps({
            "password": self.password
        }).encode()

        request = urllib.request.Request(url, data=payload, method="POST")
        request.add_header("Content-Type", "application/json")

        try:
            with urllib.request.urlopen(request) as response:
                data = json.loads(response.read().decode())
                self.token = data["auth"]["client_token"]
                logger.debug("Vault authentication successful")
        except urllib.error.HTTPError as e:
            raise RuntimeError("Vault login failed: {}".format(e.read().decode()))
        except Exception as e:
            raise RuntimeError("Vault login error: {}".format(str(e)))

    def read_kv_v2(self, profile):
        logger.debug("Reading Vault secret for profile: %s", profile)

        url = "{}/v1/{}/data/aws/{}".format(
            self.address, self.mount, profile
        )

        request = urllib.request.Request(url)
        request.add_header("X-Vault-Token", self.token)

        try:
            with urllib.request.urlopen(request) as response:
                data = json.loads(response.read().decode())
                logger.debug("Vault secret successfully retrieved")
                return data["data"]["data"]
        except urllib.error.HTTPError as e:
            raise RuntimeError("Vault read failed: {}".format(e.read().decode()))
        except Exception as e:
            raise RuntimeError("Vault read error: {}".format(str(e)))

    def revoke_token(self):
        if not self.token:
            return

        logger.debug("Revoking Vault token")

        url = "{}/v1/auth/token/revoke-self".format(self.address)

        request = urllib.request.Request(url, method="POST")
        request.add_header("X-Vault-Token", self.token)

        try:
            urllib.request.urlopen(request)
            logger.debug("Vault token revoked")
        except Exception:
            logger.warning("Vault token revoke failed (ignored)")


# --------------------------------------------------
# AWS Credential Formatter
# --------------------------------------------------

class AwsCredentialFormatter:
    @staticmethod
    def format(credentials):
        try:
            output = {
                "Version": 1,
                "AccessKeyId": credentials["aws_access_key_id"],
                "SecretAccessKey": credentials["aws_secret_access_key"]
            }

            if "aws_session_token" in credentials:
                output["SessionToken"] = credentials["aws_session_token"]

            return json.dumps(output)
        except KeyError:
            raise ValueError("Invalid AWS credentials format in Vault")


# --------------------------------------------------
# CLI
# --------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description="Retrieve AWS credentials from Vault for AWS credential_process usage.",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        "profile",
        help="Vault AWS profile name (e.g., dev, prod)"
    )

    parser.add_argument(
        "--config",
        default="/etc/vault-aws.ini",
        help="Path to configuration INI file (default: /etc/vault-aws.ini)"
    )

    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging"
    )

    parser.add_argument(
        "--version",
        action="version",
        version="vault-aws {}".format(__version__)
    )

    return parser.parse_args()


# --------------------------------------------------
# Main
# --------------------------------------------------

def main():
    args = parse_args()

    setup_logging(debug=args.debug)

    try:
        logger.debug("Starting vault_aws execution")

        config = VaultConfig(args.config)
        client = VaultClient(config)

        client.login()
        credentials = client.read_kv_v2(args.profile)
        client.revoke_token()

        print(AwsCredentialFormatter.format(credentials))

        logger.debug("Execution completed successfully")

    except Exception as e:
        logger.error("Execution failed: %s", str(e))
        sys.exit(1)


if __name__ == "__main__":
    main()
