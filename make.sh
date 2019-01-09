#!/bin/sh
set -x
dmd -m64 fairskill.d
rm *.o
