#!/bin/bash
URL=$1
if [ -z "$URL" ]; then
  echo "No URL specified"
else
  echo "Render to PDF: $URL"
  google-chrome-stable --headless --disable-gpu --print-to-pdf $URL --virtual-time-budget=10000
  chmod 644 output.pdf
  ls -l output.pdf
fi
