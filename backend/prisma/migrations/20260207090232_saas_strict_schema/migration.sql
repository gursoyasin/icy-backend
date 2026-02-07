/*
  Warnings:

  - A unique constraint covering the columns `[clinicId,name]` on the table `Branch` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[slug]` on the table `Clinic` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[clinicId,phoneNumber]` on the table `Patient` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[clinicId,email]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Made the column `clinicId` on table `Appointment` required. This step will fail if there are existing NULL values in that column.
  - Made the column `clinicId` on table `Branch` required. This step will fail if there are existing NULL values in that column.
  - Added the required column `slug` to the `Clinic` table without a default value. This is not possible if the table is not empty.
  - Made the column `clinicId` on table `Patient` required. This step will fail if there are existing NULL values in that column.
  - Made the column `clinicId` on table `User` required. This step will fail if there are existing NULL values in that column.

*/
-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_clinicId_fkey";

-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_patientId_fkey";

-- DropForeignKey
ALTER TABLE "Branch" DROP CONSTRAINT "Branch_clinicId_fkey";

-- DropForeignKey
ALTER TABLE "Patient" DROP CONSTRAINT "Patient_clinicId_fkey";

-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_clinicId_fkey";

-- DropIndex
DROP INDEX "User_email_key";

-- AlterTable
ALTER TABLE "Appointment" ADD COLUMN     "branchId" TEXT,
ALTER COLUMN "clinicId" SET NOT NULL;

-- AlterTable
ALTER TABLE "Branch" ADD COLUMN     "phone" TEXT,
ALTER COLUMN "clinicId" SET NOT NULL;

-- AlterTable
ALTER TABLE "Clinic" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "plan" TEXT NOT NULL DEFAULT 'BASIC',
ADD COLUMN     "slug" TEXT NOT NULL;

-- AlterTable
ALTER TABLE "Patient" ALTER COLUMN "clinicId" SET NOT NULL;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ALTER COLUMN "clinicId" SET NOT NULL;

-- CreateTable
CREATE TABLE "Consent" (
    "id" TEXT NOT NULL,
    "clinicId" TEXT NOT NULL,
    "patientId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "granted" BOOLEAN NOT NULL DEFAULT false,
    "grantedAt" TIMESTAMP(3),
    "revokedAt" TIMESTAMP(3),
    "source" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Consent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Consent_clinicId_idx" ON "Consent"("clinicId");

-- CreateIndex
CREATE UNIQUE INDEX "Consent_clinicId_patientId_type_key" ON "Consent"("clinicId", "patientId", "type");

-- CreateIndex
CREATE INDEX "Appointment_clinicId_idx" ON "Appointment"("clinicId");

-- CreateIndex
CREATE INDEX "Appointment_clinicId_date_idx" ON "Appointment"("clinicId", "date");

-- CreateIndex
CREATE INDEX "Appointment_clinicId_patientId_idx" ON "Appointment"("clinicId", "patientId");

-- CreateIndex
CREATE INDEX "Branch_clinicId_idx" ON "Branch"("clinicId");

-- CreateIndex
CREATE UNIQUE INDEX "Branch_clinicId_name_key" ON "Branch"("clinicId", "name");

-- CreateIndex
CREATE UNIQUE INDEX "Clinic_slug_key" ON "Clinic"("slug");

-- CreateIndex
CREATE INDEX "Patient_clinicId_idx" ON "Patient"("clinicId");

-- CreateIndex
CREATE UNIQUE INDEX "Patient_clinicId_phoneNumber_key" ON "Patient"("clinicId", "phoneNumber");

-- CreateIndex
CREATE INDEX "User_clinicId_idx" ON "User"("clinicId");

-- CreateIndex
CREATE UNIQUE INDEX "User_clinicId_email_key" ON "User"("clinicId", "email");

-- AddForeignKey
ALTER TABLE "Branch" ADD CONSTRAINT "Branch_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Patient" ADD CONSTRAINT "Patient_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Appointment" ADD CONSTRAINT "Appointment_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "Patient"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Consent" ADD CONSTRAINT "Consent_clinicId_fkey" FOREIGN KEY ("clinicId") REFERENCES "Clinic"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Consent" ADD CONSTRAINT "Consent_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "Patient"("id") ON DELETE CASCADE ON UPDATE CASCADE;
