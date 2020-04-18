#! /usr/bin/env python3

import sys

for line in sys.stdin:
    print( "{0:02x}".format(int(line.strip(),2)) )
