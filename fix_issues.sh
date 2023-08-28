#!/bin/bash


# fix issue in /usr/share/fsl/5.0/bin/imglob
file_path="/usr/share/fsl/5.0/bin/imglob"
python_version="2"

sed -i "1s/$/$python_version/" $file_path

