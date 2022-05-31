# Confetti
Event venue managing software. Using PostgreSQL, Express.js and Next.js

## Quick-Start guide:
- `cd` into api folder and run `npm i`.
- `cd` back out to project root and `cp example.env .env`, modify if needed.
- Run `docker-compose up`.

## Troubleshooting
- If api fails the first time, run `docker pull node:alpine`.
- If the database gets corrupted or is otherwise not working, delete the db-data folder to reinitialize it.

# Dependencies
`node` `docker` `docker-compose`