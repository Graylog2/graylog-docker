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
parser.add_argument('--bump', dest='bump',
                    choices=['graylog', 'forwarder'], help="Bump the given version")
parser.add_argument('--version', dest='version',
                    help="The new version and revision")

if len(sys.argv) == 1:
    parser.print_help(sys.stderr)
    sys.exit(1)

args = parser.parse_args()

if args.bump and not args.version:
    parser.error('Missing --version parameter')

version_parsed = None

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
        from jinja2 import Template
        with open('README.j2', 'r') as template_file:
            j2_template = Template(template_file.read())

        with open("README.md", "w") as readme_file:
            readme_file.write(j2_template.render(version_parsed))

    if args.bump == 'graylog':
        print(f'Bumping {args.bump} to {args.version}')

        # 6.0.0-alpha.1-1 => version="6.0.0", suffixes=["alpha.1", "1"]
        # 6.0.0           => version="6.0.0", suffixes=[]
        version, *suffixes = args.version.split('-', 2)
        # 6.0.0 => major=6, minor=0, patch= 0
        major, minor, patch = version.split('.', 2)

        suffix = suffixes[0] if len(suffixes) > 0 else None
        release = suffixes[1] if len(suffixes) > 1 else 1

        version_parsed[args.bump]['major_version'] = major
        version_parsed[args.bump]['minor_version'] = minor
        version_parsed[args.bump]['patch_version'] = f'{patch}-{suffix}' if suffix else patch
        version_parsed[args.bump]['release'] = int(release)

        print(version_parsed[args.bump])
    if args.bump == 'forwarder':
        print(f'Bumping {args.bump} to {args.version}')

        # 6.0-alpha.1-1 => version="6.0", suffixes=["alpha.1", "1"]
        # 6.0           => version="6.0", suffixes=[]
        version, *suffixes = args.version.split('-', 2)
        suffix = suffixes[0] if len(suffixes) > 0 else None
        release = suffixes[1] if len(suffixes) > 1 else 1

        version_parsed[args.bump]['version'] = f'{version}-{suffix}' if suffix else version
        version_parsed[args.bump]['release'] = int(release)

        print(version_parsed[args.bump])


if version_parsed and args.bump:
    with open('version.yml', 'w') as f:
        yaml.dump(version_parsed, f, sort_keys=False)

    with open('version.yml', 'r+') as f:
        content = f.read()
        f.seek(0, 0)
        # Preserve some comments
        f.write('# For pre-releases: patch_version=0-beta.1, patch_version=0-rc.1\n')
        f.write('# For GA releases:  patch_version=0\n')
        f.write(content)
