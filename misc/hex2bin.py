#! /usr/bin/env python3

import sys

for line in sys.stdin:
    print( "{0:08b}".format(int(line.strip(),16)) )
