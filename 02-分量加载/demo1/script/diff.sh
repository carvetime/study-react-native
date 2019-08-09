#!/bin/bash

bundle1="../dist/index.ios.bundle"
bundle2="../dist/common.bundle"
path="../dist/business.path"

diff $bundle1 $bundle2 >> $path