#!/usr/bin/env python3

import yaml
import argparse
import sys

parser = argparse.ArgumentParser(
    description='Release utility for the Graylog Docker image.')
parser.add_argument('--get-graylog-version',
                    help="Get Graylog image version.", action='store_true')
parser.add_argument('--get-forwarder-version',
                    help="Get Forwarder version.", action='store_true')
parser.add_argument('--get-forwarder-image-version',
                    help="Get Forwarder image version.", action='store_true')
parser.add_argument('--generate-readme',
                    help="Generate a new README.md with the latest tags", action='store_true')
parser.add_argument('--template', type=str)

if len(sys.argv) == 1:
    parser.print_help(sys.stderr)
    sys.exit(1)

args = parser.parse_args()

with open('version.yml', 'r') as version_file:
    version_parsed = yaml.safe_load(version_file)

    if args.get_graylog_version:
        print(str(version_parsed['graylog']['major_version']) + '.' + str(version_parsed['graylog']
              ['minor_version']) + '.' + str(version_parsed['graylog']['patch_version']), end='')

    if args.get_forwarder_version:
        print(str(version_parsed['forwarder']['version']), end='')

    if args.get_forwarder_image_version:
        print(str(version_parsed['forwarder']['version']) + '-' +
              str(version_parsed['forwarder']['release']), end='')

    if args.generate_readme:
        template_file = args.template

        if not template_file:
            print('ERROR: Missing --template option')
            sys.exit(1)

        from jinja2 import Environment, FileSystemLoader
        env = Environment(loader=FileSystemLoader('.'))
        j2_template = env.get_template(template_file)

        with open("README.md", "w") as readme_file:
            readme_file.write(j2_template.render(version_parsed))
