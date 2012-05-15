#!/bin/sh
echo Script START
rm -rf log
make testuni 1> log & gnuplot plotter
