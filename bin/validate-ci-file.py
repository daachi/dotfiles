#!/usr/bin/python3
import requests, sys, yaml, json, logging, argparse, pdb
from lxml import html
from urllib.parse import unquote

parser = argparse.ArgumentParser()
parser.add_argument("file", help="Yaml filename to validate")
parser.add_argument("-l", "--logging", help="Log activity and data to syslog", action="store_true")
parser.add_argument("-t", "--trace", help="Use PDB to debug the execution step by step", action="store_true")
parser.add_argument("-L", "--loghttp", help="Activate the logging inside the requests lib", action="store_true")
args = parser.parse_args()

private_token = "8bxBzyd5aV5cgC-vT6js"

url = "https://gitlab.com/api/v4/ci/lint?private_token="+private_token
logging.basicConfig(filename="/tmp/validator.log", level=logging.DEBUG)

"""
LOGGING FUNCTION for HTTP
"""

def loghttp():
    import http.client as http_client

    logging.basicConfig(level=logging.INFO)
    logging.getLogger().setLevel(logging.INFO)
    requests_log = logging.getLogger("requests.packages.urllib3")
    requests_log.setLevel(logging.INFO)
    requests_log.propagate = True

try:
    if args.trace: pdb.set_trace()

    if args.loghttp: loghttp()

    if args.logging: logging.debug("File is {}".format(args.file))
    session_requests = requests.session()
    gitlab_ci_yml = open(args.file, 'r')
    yaml = yaml.load(gitlab_ci_yml)
    if args.logging: logging.debug("Yaml read is {}".format(yaml))
    gitlab_ci_yml.close()

    content = json.dumps(json.dumps(yaml))
    if args.logging: logging.debug("JSON double encoded is {}".format(content))
    content = '{"content": ' + content + '}'
    if args.logging: logging.debug("Final content to be sent is {}".format(content))

    result = session_requests.post(
            url,
            data = content,
            headers = {'Content-Type' : "application/json"}
    )
    if args.logging: logging.debug("Headers sent were {}".format(result.request.headers))
    if args.logging: logging.debug("Content sent was {}".format(unquote(result.request.body)))

    print(result)
    print(result.text)

except Exception as e:
    print(e)
