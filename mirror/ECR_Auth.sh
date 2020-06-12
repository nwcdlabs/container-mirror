#!/bin/bash
env

aws configure --profile=ChinaECR set aws_access_key_id $ecr_ak
aws configure --profile=ChinaECR set aws_secret_access_key $ecr_sk
aws configure --profile=ChinaECR set default.region cn-northwest-1