#!/bin/bash

PACKAGE_NAME=$1

yum upgrade -y ${PACKAGE_NAME}
