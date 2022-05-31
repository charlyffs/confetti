#!/bin/bash
docker build ./api/ -t confetti-api:latest;
docker build ./database/ -t confetti-db:latest;