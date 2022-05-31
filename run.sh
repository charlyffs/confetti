#!/bin/bash
docker build ./api/ -t confetti-api:latest;
docker-compose up;