#!/bin/bash
URL=$1
if [ -z "$URL" ]
then
  echo "No URL specified"
else
  echo "Render to PDF: $URL"
  rm output.pdf
  google-chrome-stable --headless --disable-gpu --print-to-pdf $URL --virtual-time-budget=10000 --print-to-pdf-no-header
  chmod 666 output.pdf
fi
