#!/bin/bash

# udpate dist dir

if [ -e dist ]; then
    rm -rf dist
fi

mkdir dist
cp haxelib.json LICENSE README src/test.n dist

mkdir dist/redis
cp src/redis/* dist/redis

# replace haxelib package zip

if [ -e hxneko-redis.zip ]; then
    rm -rf hxneko-redis.zip
fi

cd dist
zip -r ../hxneko-redis.zip *
cd ..

