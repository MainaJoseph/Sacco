#!/bin/bash


if [ $# -eq 0 ]; then
    java -Xmx256m -jar build/baraza.jar server ./projects/
else
    java -Xmx256m -jar build/baraza.jar tomcat ./projects/ $1
fi

