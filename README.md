# confetti

## How to run:
- `cd` into api folder and run `npm i`.
- `cd` back out to root and `cp example.env .env`.
- run `docker-compose up`.

## Troubleshooting
- if api fails the first time, run `docker pull node:alpine`.
- if the database gets corrupted or is otherwise not working, delete the db-data folder to reinitialize it.

# dependencies
`docker` `docker-compose`