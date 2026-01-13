# Licensing Service

> **Multi-project license management and payment processing platform**

A production-ready SaaS licensing and subscription management platform built with NestJS, Angular, PostgreSQL, and Prisma. Supports Stripe, Patreon, and Ko-fi payment integrations with cryptographic license key generation and validation.

---

## Overview

| Property | Value |
|----------|-------|
| **API Framework** | NestJS 11 |
| **Admin UI** | Angular 17+ |
| **Database** | PostgreSQL 15+ |
| **ORM** | Prisma 7 |
| **Authentication** | JWT + API Key |
| **License Signing** | Ed25519 (quantum-resistant) |

**Core Features:**
- License key generation with Ed25519 cryptographic signatures
- Payment provider webhooks (Stripe, Patreon, Ko-fi)
- Tiered subscription management (FREE, PATREON, COMMERCIAL)
- Public pricing API for integration with marketing sites
- Admin dashboard for license management
- Email notifications via Resend
- Audit logging and analytics
- Machine activation tracking

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Licensing Service                         │
│                                                               │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐       │
│  │   Stripe    │   │  Patreon    │   │   Ko-fi     │       │
│  │  Webhooks   │   │  Webhooks   │   │  Webhooks   │       │
│  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘       │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            ▼                                   │
│         ┌──────────────────────────────────────┐             │
│         │     Webhook Processing Service       │             │
│         │  (Deduplication + Verification)      │             │
│         └──────────────────┬───────────────────┘             │
│                            ▼                                   │
│         ┌──────────────────────────────────────┐             │
│         │       License Management             │             │
│         │  (CRUD + Tier Assignment)            │             │
│         └──────────────────┬───────────────────┘             │
│                            ▼                                   │
│         ┌──────────────────────────────────────┐             │
│         │    Cryptographic Service             │             │
│         │  (Ed25519 Key Generation)            │             │
│         └──────────────────────────────────────┘             │
│                                                               │
│  ┌──────────────────┐              ┌──────────────────┐     │
│  │  Public API      │              │  Admin Dashboard │     │
│  │  /api/pricing    │              │  /admin/*        │     │
│  │  /api/licenses   │              │  (Angular SPA)   │     │
│  └──────────────────┘              └──────────────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## Tech Stack

### Backend (NestJS API)

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Framework** | NestJS 11 | REST API server |
| **Database** | PostgreSQL 15+ | Primary data store |
| **ORM** | Prisma 7 | Type-safe database access |
| **Authentication** | Passport JWT | Admin authentication |
| **Validation** | class-validator | Request validation |
| **Security** | Helmet, CORS, Rate Limiting | Request protection |
| **Email** | Resend API | Transactional emails |
| **Documentation** | Swagger/OpenAPI | Auto-generated API docs |

### Frontend (Admin UI)

| Component | Technology |
|-----------|-----------|
| **Framework** | Angular 17+ |
| **UI Library** | Ionic Components |
| **State Management** | RxJS |
| **HTTP Client** | Angular HttpClient |

### Cryptography

| Feature | Algorithm | Purpose |
|---------|-----------|---------|
| **License Signing** | Ed25519 | Digital signatures (quantum-resistant) |
| **Database Encryption** | AES-256 | Sensitive field encryption |
| **Password Hashing** | bcrypt | Admin password storage |

---

## Quick Start

### Prerequisites

- Node.js 20.x LTS
- PostgreSQL 15+
- Docker & Docker Compose (optional)

### Installation

```bash
# 1. Clone repository
git clone https://github.com/yourusername/licensing-service.git
cd licensing-service

# 2. Install dependencies
npm install

# 3. Set up environment variables
cp .env.example .env
# Edit .env with your configuration (see Environment Variables section)

# 4. Start PostgreSQL (if not running)
docker run -d \
  --name licensing-postgres \
  -p 5432:5432 \
  -e POSTGRES_DB=license_db \
  -e POSTGRES_USER=license_user \
  -e POSTGRES_PASSWORD=password \
  postgres:15-alpine

# 5. Generate Prisma client
npx prisma generate

# 6. Run database migrations
npx prisma migrate deploy

# 7. (Optional) Seed pricing tiers
npx prisma db seed
```

### Development Mode

```bash
# Start API (port 3200)
nx serve license-api

# Access Swagger docs
open http://localhost:3200/docs

# Test public endpoint
curl http://localhost:3200/api/pricing
```

---

## Environment Variables

Create a `.env` file at the project root. See `.env.example` for a complete template.

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| **DATABASE_URL** | PostgreSQL connection string | `postgresql://user:pass@localhost:5432/license_db` |
| **ENCRYPTION_KEY** | 64 hex chars for AES-256 | `openssl rand -hex 32` |
| **ADMIN_API_KEY** | Admin API authentication | `openssl rand -hex 32` |
| **JWT_SECRET** | JWT token signing key | `openssl rand -hex 32` |

### Payment Providers (Optional)

| Variable | Provider | Required For |
|----------|----------|--------------|
| **STRIPE_SECRET_KEY** | Stripe | Credit card payments |
| **STRIPE_WEBHOOK_SECRET** | Stripe | Webhook verification |
| **STRIPE_PRODUCT_ID** | Stripe | Product mapping |
| **PATREON_CLIENT_ID** | Patreon | OAuth integration |
| **PATREON_CLIENT_SECRET** | Patreon | OAuth callback |
| **PATREON_WEBHOOK_SECRET** | Patreon | Webhook verification |
| **KOFI_VERIFICATION_TOKEN** | Ko-fi | Donation webhooks |

### Email Configuration

| Variable | Description |
|----------|-------------|
| **RESEND_API_KEY** | Resend API key for transactional emails |

### Server Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| **PORT** | 3200 | API server port |
| **NODE_ENV** | development | `development` or `production` |
| **CORS_ORIGINS** | localhost | Comma-separated allowed origins |

### Generating Secrets

```bash
# Encryption key (64 hex characters = 32 bytes)
openssl rand -hex 32

# API keys (base64 encoded)
openssl rand -base64 32

# JWT secret
openssl rand -hex 32
```

---

## API Documentation

### Swagger UI

Interactive API documentation is available at:

```
http://localhost:3200/docs
```

### Public Endpoints

#### GET /api/pricing

Fetch active pricing tiers (no authentication required).

**Rate Limit:** 100 requests/60 seconds per IP

**Response:**
```json
[
  {
    "id": "cm3abc123",
    "name": "FREE",
    "displayName": "Free",
    "description": "Perfect for hobbyists",
    "maxNodes": 1,
    "maxConcurrentJobs": 2,
    "priceMonthly": 0,
    "priceYearly": null,
    "isActive": true
  }
]
```

**Usage:**
```bash
curl http://localhost:3200/api/pricing
```

#### POST /api/licenses/activate

Activate a license on a machine.

**Request:**
```json
{
  "licenseKey": "LICENSE-KEY-HERE",
  "machineId": "unique-machine-id",
  "machineName": "Dev Workstation"
}
```

**Response:**
```json
{
  "success": true,
  "license": {
    "tier": "PATREON_PRO",
    "maxNodes": 5,
    "maxConcurrentJobs": 10,
    "expiresAt": null
  }
}
```

### Admin Endpoints

All admin endpoints require `x-api-key` header.

#### POST /api/admin/licenses

Generate a new license.

**Headers:**
```
x-api-key: your-admin-api-key
Content-Type: application/json
```

**Request:**
```json
{
  "email": "user@example.com",
  "tier": "PATREON_PRO",
  "expiresAt": "2026-12-31T23:59:59Z"
}
```

**Response:**
```json
{
  "id": "cm4xyz789",
  "key": "LICENSE-PRO-eyJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20i...abc123",
  "email": "user@example.com",
  "tier": "PATREON_PRO",
  "status": "ACTIVE",
  "maxNodes": 5,
  "maxConcurrentJobs": 10
}
```

---

## Database Schema

### Core Models

| Model | Purpose |
|-------|---------|
| **License** | License keys with tier, status, and expiration |
| **LicenseActivation** | Machine activations (machine ID + IP tracking) |
| **PricingTier** | Subscription tiers with pricing and limits |
| **WebhookEvent** | Payment provider webhook log |
| **AdminUser** | Admin dashboard users with role-based access |
| **AuditLog** | Action audit trail |
| **EmailTemplate** | Customizable email templates |

### License Tiers

| Tier | Max Nodes | Max Jobs |
|------|-----------|----------|
| **FREE** | 1 | 2 |
| **PATREON_SUPPORTER** | 2 | 4 |
| **PATREON_PLUS** | 3 | 6 |
| **PATREON_PRO** | 5 | 10 |
| **PATREON_ULTIMATE** | 10 | 20 |
| **COMMERCIAL_STARTER** | 5 | 10 |
| **COMMERCIAL_PRO** | 20 | 50 |
| **COMMERCIAL_ENTERPRISE** | Unlimited | Unlimited |

---

## Ed25519 Keypair Management

### Critical: Backup Your Keys

The licensing service uses **Ed25519 cryptographic signatures** to generate and validate license keys. **If the keypair is lost, all existing licenses become invalid.**

#### Keypair Location

Keys are stored in: `./keys/` (relative to app root)

```
./keys/
├── private.pem  (🔒 NEVER COMMIT TO GIT)
├── public.pem   (✅ Safe to share)
```

#### Automatic Generation

On first startup, the API automatically generates a new Ed25519 keypair if none exists.

**DO NOT COMMIT KEYS TO GIT.** Add `keys/` to `.gitignore`.

#### Backup Procedure

**Development:**
```bash
# Backup keys
cp -r ./keys ./keys.backup-$(date +%F)

# Store in secure location (NOT git)
cp -r ./keys ~/secure-backups/licensing-keys-$(date +%F)
```

**Production:**

Use a secret management service:

| Platform | Service |
|----------|---------|
| AWS | AWS Secrets Manager + S3 (versioned) |
| Azure | Azure Key Vault |
| Google Cloud | Google Secret Manager |
| Self-Hosted | HashiCorp Vault |

**Automated Backup Script:**

```bash
#!/bin/bash
# backup-keys.sh

DATE=$(date +%Y-%m-%d-%H%M%S)
BACKUP_DIR="/secure/backups/licensing-keys"
KEYS_DIR="./keys"

mkdir -p "$BACKUP_DIR"
tar -czf "$BACKUP_DIR/keys-$DATE.tar.gz" -C "$KEYS_DIR" .

# Upload to S3 (example)
aws s3 cp "$BACKUP_DIR/keys-$DATE.tar.gz" \
  s3://your-bucket/licensing-keys/ \
  --server-side-encryption AES256

echo "✅ Keys backed up: $BACKUP_DIR/keys-$DATE.tar.gz"
```

**Cron (daily backup at 3 AM):**
```cron
0 3 * * * /path/to/backup-keys.sh
```

#### Recovery

If keys are lost:

1. **Stop the API immediately**
2. **Restore from backup:**
   ```bash
   tar -xzf keys-backup.tar.gz -C ./keys
   chmod 600 ./keys/private.pem
   chmod 644 ./keys/public.pem
   ```
3. **Restart API**
4. **Verify health check:** `curl http://localhost:3200/health`

**If no backup exists:** All licenses must be regenerated (catastrophic failure).

---

## Deployment

### Docker Compose (Recommended)

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with production values

# 2. Start services
docker-compose -f docker/docker-compose.yml up -d

# 3. Verify health
curl http://localhost:3000/health
```

**Important:** Mount `./keys` as a volume to persist the keypair:

```yaml
# docker-compose.yml
services:
  license-api:
    volumes:
      - ./keys:/app/keys:ro  # Read-only in production
```

### Manual Deployment

```bash
# 1. Build
npm run build

# 2. Run migrations
npx prisma migrate deploy

# 3. Start API
node dist/apps/license-api/main.js
```

### Production Checklist

- [ ] PostgreSQL database provisioned (with backups)
- [ ] Environment variables configured
- [ ] Ed25519 keypair backed up to secure storage
- [ ] CORS origins restricted to production domains
- [ ] Stripe/Patreon webhooks configured
- [ ] Email templates customized
- [ ] Rate limits tuned for production traffic
- [ ] SSL/TLS certificate installed (HTTPS only)
- [ ] Admin API keys rotated and secured

---

## Security

### Implemented Protections

| Protection | Implementation |
|------------|----------------|
| **Webhook Verification** | Signature verification (timing-safe comparison) |
| **Idempotency** | Event deduplication via `providerEventId` |
| **Rate Limiting** | Throttling on all endpoints (configurable per route) |
| **CORS** | Whitelist-based origin validation |
| **Helmet** | Security headers (CSP, XSS protection) |
| **Input Validation** | class-validator on all DTOs |
| **Audit Logging** | Action tracking with user, IP, and timestamp |
| **Ed25519 Signatures** | Quantum-resistant license signing |

### Best Practices

1. **Rotate API keys every 90 days**
2. **Use HTTPS in production** (no HTTP)
3. **Limit CORS origins** to known domains
4. **Monitor webhook failures** for security events
5. **Backup database daily** (encrypted backups)
6. **Review audit logs** for suspicious activity

---

## Testing

```bash
# Unit tests
nx test license-api

# Watch mode
nx test license-api --watch

# Coverage report
nx test license-api --coverage

# E2E tests (requires PostgreSQL)
nx e2e license-api-e2e
```

---

## Troubleshooting

### Database Connection Errors

**Symptom:** `Can't reach database server`

**Fix:**
```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
psql -h localhost -U license_user -d license_db

# Verify DATABASE_URL
echo $DATABASE_URL
```

### Encryption Key Errors

**Symptom:** `ENCRYPTION_KEY must be 64 hex characters`

**Fix:**
```bash
# Generate valid key
openssl rand -hex 32

# Update .env
echo "ENCRYPTION_KEY=$(openssl rand -hex 32)" >> .env
```

### Build Errors (Missing Prisma Client)

**Symptom:** `Cannot find module '@prisma/client'`

**Fix:**
```bash
npx prisma generate
npm run build
```

### Webhook Signature Verification Failed

**Symptom:** `Webhook signature verification failed`

**Fix:**
1. Verify webhook secret matches provider dashboard
2. Test locally with provider CLI:
   ```bash
   # Stripe
   stripe listen --forward-to localhost:3200/api/stripe/webhook
   ```
3. Use signing secret from CLI output

---

## Project Structure

```
licensing-service/
├── apps/
│   ├── license-api/          # NestJS REST API
│   │   ├── src/
│   │   │   ├── auth/         # JWT authentication
│   │   │   ├── crypto/       # Ed25519 signing
│   │   │   ├── licenses/     # License CRUD
│   │   │   ├── pricing/      # Pricing management
│   │   │   ├── stripe/       # Stripe webhooks
│   │   │   ├── patreon/      # Patreon webhooks
│   │   │   ├── kofi/         # Ko-fi webhooks
│   │   │   ├── email/        # Email service
│   │   │   └── audit/        # Audit logging
│   │   └── prisma/
│   │       └── schema.prisma # Database schema
│   └── license-fe/           # Angular admin dashboard (if exists)
├── prisma/
│   ├── schema.prisma         # Prisma schema
│   └── migrations/           # Migration history
├── docker/
│   └── docker-compose.yml    # Docker orchestration
├── .env.example              # Environment template
├── nx.json                   # Nx workspace config
└── README.md                 # This file
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m 'feat: add new feature'`
4. Push to branch: `git push origin feature/your-feature`
5. Open a Pull Request

### Commit Convention

```
<type>(<scope>): <description>

Types: feat, fix, docs, refactor, test, chore
```

**Examples:**
- `feat(licenses): add license revocation endpoint`
- `fix(webhooks): handle duplicate Stripe events`
- `docs(readme): update deployment instructions`

---

## License

MIT License - see [LICENSE](LICENSE) file for details.

---

## Support

For issues or questions:
- **GitHub Issues:** https://github.com/yourusername/licensing-service/issues
- **Documentation:** See `apps/license-api/README.md` for detailed API docs
- **Email:** support@yourdomain.com

---

<div align="center">

**Production-ready SaaS licensing platform**

[API Docs](http://localhost:3200/docs) • [Database Schema](prisma/schema.prisma) • [Environment Setup](.env.example)

</div>
