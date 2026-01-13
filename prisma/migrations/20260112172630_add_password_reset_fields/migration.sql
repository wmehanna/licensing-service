-- AlterTable
ALTER TABLE "admin_users" ADD COLUMN "reset_token" TEXT,
ADD COLUMN "reset_token_expiry" TIMESTAMP(3);
