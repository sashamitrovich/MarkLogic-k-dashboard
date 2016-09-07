#!/bin/bash

./import-stop-words.sh
./ml local mlcp -options_file import-internal-docs.options
