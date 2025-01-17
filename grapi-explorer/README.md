# Kopano Grapi Explorer

The Grapi Explorer is a fork of the Microsoft Graph Explorer, which has been modified so that it can connect against a self hosted Kopano GRAPI. Similar to the Grapi Playground it can be used to inspect the flows that are required to use the Kopano RestAPI and experiment with different query types.

## How to use the Grapi Explorer?

 1. Add the `grapi-explorer.yml` to the `COMPOSE_FILE` variable in your `.env` file.

 Example:
```
COMPOSE_FILE=docker-compose.yml:docker-compose.ports.yml:grapi-explorer/grapi-explorer.yml
```

 2. Run `docker-compose up -d` and you will find the grapi-explorer at `https://your-fqdn/grapi-explorer/`.