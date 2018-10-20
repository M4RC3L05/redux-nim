#!/usr/bin/env bash

nim doc --project src/redux_nim.nim
rm -rf docs
mkdir docs
mv src/htmldocs/* docs
mv docs/redux_nim.html docs/index.html
rm -rf src/htmldocs
