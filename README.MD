# Petistaan-MS

Central hub for the **Petistaan** microservices ecosystem — a Spring Boot pet management
system built across six independent services.

This repo contains no application code. It exists to provide a single entry point for:
system architecture, build order, Docker Compose setup, and inter-service wiring.

---

## Table of Contents

- [Services](#services)
- [Architecture](#architecture)
- [Inter-Service Communication](#inter-service-communication)
- [Database](#database)
- [Docker Compose](#docker-compose)
- [Build Order](#build-order)
- [Running the Full Stack](#running-the-full-stack)
- [Branch Strategy](#branch-strategy)

---

## Services

| Service | Repo | Port | Responsibility |
|---|---|---|---|
| [Petistaan-EurekaServer](https://github.com/AbhishekSharma-99/Petistaan-EurekaServer) | `Petistaan-EurekaServer` | 8761 | Service discovery |
| [Petistaan-ConfigServer](https://github.com/AbhishekSharma-99/Petistaan-ConfigServer) | `Petistaan-ConfigServer` | 8888 | Centralized config |
| [Petistaan-APIGateway](https://github.com/AbhishekSharma-99/Petistaan-APIGateway) | `Petistaan-APIGateway` | 8080 | Single entry point, routing |
| [Petistaan-OwnerMS](https://github.com/AbhishekSharma-99/Petistaan-OwnerMS) | `Petistaan-OwnerMS` | 8081 | Owner registration, pet lifecycle |
| [Petistaan-PetMS](https://github.com/AbhishekSharma-99/Petistaan-PetMS) | `Petistaan-PetMS` | 8082 | Pet population statistics |
| [Petistaan-MailMS](https://github.com/AbhishekSharma-99/Petistaan-MailMS) | `Petistaan-MailMS` | 8083 | Transactional email dispatch |

---

## Architecture

```
                        ┌────────────────────┐
                        │  Petistaan-Eureka  │  :8761
                        │   (Service Reg.)   │
                        └────────┬───────────┘
                                 │  all services register here
          ┌──────────────────────┼──────────────────────────┐
          │                      │                          │
┌─────────▼──────────┐  ┌────────▼───────────┐  ┌──────────▼─────────┐
│ Petistaan-Config   │  │ Petistaan-APIGateway│  │  Petistaan-OwnerMS │
│    :8888           │  │     :8080           │  │      :8081         │
│ (Centralized cfg)  │  │ (Routing / Entry)   │  │ (Owner + Pet CRUD) │
└────────────────────┘  └────────┬────────────┘  └──────┬──────┬──────┘
                                 │                      │      │
                        ┌────────▼────────┐   ┌────────▼──┐  ┌▼──────────────┐
                        │  External Client│   │Petistaan  │  │ Petistaan     │
                        └─────────────────┘   │  PetMS    │  │  MailMS       │
                                              │  :8082    │  │  :8083        │
                                              │(Statistics)│  │(Email dispatch│
                                              └────────────┘  └───────────────┘
```

---

## Inter-Service Communication

| Caller | Callee | Trigger | Mechanism |
|---|---|---|---|
| OwnerMS | MailMS | Owner registered (`WELCOME`) | `RestClient POST /mails` |
| OwnerMS | MailMS | Pet renamed (`MODIFY`) | `RestClient POST /mails` |
| OwnerMS | MailMS | Owner deleted (`EXIT`) | `RestClient POST /mails` |

All other service interactions are mediated through the API Gateway. MailMS is a
passive consumer — it exposes one endpoint and initiates no outbound calls.

---

## Database

> **Current state:** OwnerMS and PetMS share a single `petistaan` MySQL database.
> PetMS is read-only against this shared schema.
> Each service will be migrated to its own dedicated database in a future iteration.

| Service | Database | Access |
|---|---|---|
| OwnerMS | `petistaan` | Read + Write |
| PetMS | `petistaan` | Read-only |

---

## Docker Compose

The `docker-compose.yml` in this repo spins up the shared infrastructure — MySQL and
Mailpit — that the application services depend on.

```yaml
# docker-compose.yml provisions:
#   - MySQL 8.0        → localhost:3306
#   - Mailpit (SMTP)   → localhost:1025  (SMTP)
#                      → localhost:8025  (Web UI)
```

The application services (EurekaServer, ConfigServer, APIGateway, OwnerMS, PetMS,
MailMS) are run separately — either locally via `./mvnw spring-boot:run` in each repo,
or as containers added to this compose file in a future production setup.

---

## Build Order

Services have startup dependencies. Always start them in this order:

```
1. Petistaan-EurekaServer    (service registry — everything else registers here)
2. Petistaan-ConfigServer    (config server — services pull config on startup)
3. Petistaan-OwnerMS         (core domain — depends on MySQL + MailMS)
4. Petistaan-PetMS           (read-only stats — depends on MySQL)
5. Petistaan-MailMS          (email dispatch — depends on Mailpit)
6. Petistaan-APIGateway      (entry point — depends on Eureka to resolve routes)
```

---

## Running the Full Stack

### Step 1 — Start infrastructure

```bash
# Clone this hub repo
git clone https://github.com/AbhishekSharma-99/Petistaan-MS.git
cd Petistaan-MS

# Copy and fill in environment values
cp .env.example .env
# Edit .env — set MY_SQL_ROOT_PASSWORD, MY_SQL_DATABASE, MY_SQL_USERNAME, MY_SQL_PASSWORD

# Start MySQL + Mailpit
docker compose up -d
```

**Required `.env` keys:**

```dotenv
MY_SQL_ROOT_PASSWORD=yourpassword
MY_SQL_DATABASE=petistaan
MY_SQL_USERNAME=root
MY_SQL_PASSWORD=yourpassword
```

### Step 2 — Start application services (in order)

Clone each repo and run in a separate terminal, following the [build order](#build-order).
Each service has its own `.env.example` — see its individual README for details.

```bash
# Example — EurekaServer first
git clone https://github.com/AbhishekSharma-99/Petistaan-EurekaServer.git
cd Petistaan-EurekaServer
./mvnw spring-boot:run
```

Repeat for ConfigServer → OwnerMS → PetMS → MailMS → APIGateway.

### Step 3 — Verify

| Check | URL |
|---|---|
| Eureka dashboard | http://localhost:8761 |
| Mailpit Web UI | http://localhost:8025 |
| API Gateway | http://localhost:8080 |
| OwnerMS direct | http://localhost:8081 |
| PetMS direct | http://localhost:8082 |
| MailMS direct | http://localhost:8083 |

---

## Branch Strategy

```
main  ●──────────────────────────────────────────● (merge via PR)
       \                                         /
dev     ●──●──●──●──●──●──●──●──●──●──●──●─────
```

- `main` — stable, production-ready commits only; no direct pushes
- `dev` — integration branch; all feature work merges here first
- `feature/*` — short-lived branches off `dev` for individual concerns

The same strategy is followed in every service repo.
