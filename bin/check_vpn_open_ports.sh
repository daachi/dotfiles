#!/usr/bin/env bash

function curl-notification () {
  curl -X POST --data-urlencode "payload={\"channel\": \"@daachi\", \"username\": \"SECURITY\", \"text\": \"$1\", \"icon_emoji\": \":ghost:\"}" https://hooks.slack.com/services/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

}

if curl -s 173.45.16.132:8500/
then
  curl-notification "Port 8500 is open to the public on the VPN"
fi
