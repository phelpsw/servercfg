#!/bin/bash

git clone https://github.com/mozilla-services/syncserver
cd syncserver
make build
make test

