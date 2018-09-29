#!/usr/bin/env bash

nim doc --project src/redux_nim
mkdir
rm -rf docs
mkdir docs
mv src/htmldocs/* docs
rm -rf src/htmldocs
