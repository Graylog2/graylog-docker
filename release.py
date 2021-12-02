#!/usr/bin/env python3

import yaml
import argparse
import sys

parser = argparse.ArgumentParser(description='Release utility for the Graylog Docker image.')
parser.add_argument('--get-graylog-version', help="Get Graylog image version.", action='store_true')
parser.add_argument('--get-forwarder-version', help="Get Forwarder image version.", action='store_true')

if len(sys.argv)==1:
    parser.print_help(sys.stderr)
    sys.exit(1)

args = parser.parse_args()

if args.get_graylog_version:
    with open('version.yml', 'r') as version_file:
      version_parsed = yaml.safe_load(version_file)

    print(str(version_parsed['graylog']['major_version']) + '.' + str(version_parsed['graylog']['minor_version']) + '.' + str(version_parsed['graylog']['patch_version']), end='')

if args.get_forwarder_version:
    with open('version.yml', 'r') as version_file:
      version_parsed = yaml.safe_load(version_file)

    print(str(version_parsed['forwarder']['version']) + '-' + str(version_parsed['graylog']['release']), end='')
