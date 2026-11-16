/*
  Warnings:

  - The primary key for the `Asset` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `AssetLoan` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `eventId` on the `AssetLoan` table. All the data in the column will be lost.
  - You are about to drop the column `peminjam` on the `AssetLoan` table. All the data in the column will be lost.
  - You are about to drop the column `tglKembali` on the `AssetLoan` table. All the data in the column will be lost.
  - You are about to drop the column `tglPinjam` on the `AssetLoan` table. All the data in the column will be lost.
  - The primary key for the `Attendance` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `fotoPath` on the `Attendance` table. All the data in the column will be lost.
  - You are about to drop the column `isMock` on the `Attendance` table. All the data in the column will be lost.
  - You are about to drop the column `jarakM` on the `Attendance` table. All the data in the column will be lost.
  - You are about to drop the column `lat` on the `Attendance` table. All the data in the column will be lost.
  - You are about to drop the column `lng` on the `Attendance` table. All the data in the column will be lost.
  - You are about to drop the column `metode` on the `Attendance` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `Attendance` table. All the data in the column will be lost.
  - The primary key for the `CashLedger` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `kategori` on the `CashLedger` table. All the data in the column will be lost.
  - You are about to drop the column `refId` on the `CashLedger` table. All the data in the column will be lost.
  - You are about to alter the column `jumlah` on the `CashLedger` table. The data in that column could be lost. The data in that column will be cast from `DoublePrecision` to `Decimal(12,2)`.
  - The primary key for the `Event` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `kategori` on the `Event` table. All the data in the column will be lost.
  - You are about to drop the column `latCenter` on the `Event` table. All the data in the column will be lost.
  - You are about to drop the column `lngCenter` on the `Event` table. All the data in the column will be lost.
  - You are about to drop the column `radiusM` on the `Event` table. All the data in the column will be lost.
  - You are about to drop the column `status` on the `Event` table. All the data in the column will be lost.
  - The primary key for the `Invoice` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `jumlah` on the `Invoice` table. All the data in the column will be lost.
  - You are about to drop the column `periode` on the `Invoice` table. All the data in the column will be lost.
  - You are about to drop the column `unitId` on the `Invoice` table. All the data in the column will be lost.
  - The primary key for the `Notification` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - The primary key for the `Payment` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `buktiPath` on the `Payment` table. All the data in the column will be lost.
  - The primary key for the `User` table will be changed. If it partially fails, the table could be left without primary key constraint.
  - You are about to drop the column `unitId` on the `User` table. All the data in the column will be lost.
  - You are about to drop the `BudgetItem` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `BudgetRequest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `GuestLog` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `LetterRequest` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Unit` table. If the table is not empty, all the data it contains will be lost.
  - A unique constraint covering the columns `[userId,eventId]` on the table `Attendance` will be added. If there are existing duplicate values, this will fail.
  - A unique constraint covering the columns `[nik]` on the table `User` will be added. If there are existing duplicate values, this will fail.
  - Added the required column `kategori` to the `Asset` table without a default value. This is not possible if the table is not empty.
  - Added the required column `stokTersedia` to the `Asset` table without a default value. This is not possible if the table is not empty.
  - Added the required column `stokTotal` to the `Asset` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Asset` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `Asset` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `jumlahPinjam` to the `AssetLoan` table without a default value. This is not possible if the table is not empty.
  - Added the required column `tanggalMulai` to the `AssetLoan` table without a default value. This is not possible if the table is not empty.
  - Added the required column `tanggalSelesai` to the `AssetLoan` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `AssetLoan` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `AssetLoan` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `AssetLoan` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `assetId` on the `AssetLoan` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `fotoSelfie` to the `Attendance` table without a default value. This is not possible if the table is not empty.
  - Added the required column `latitude` to the `Attendance` table without a default value. This is not possible if the table is not empty.
  - Added the required column `longitude` to the `Attendance` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `Attendance` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `eventId` on the `Attendance` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `userId` on the `Attendance` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `id` on the `CashLedger` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `tipe` on the `CashLedger` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `lokasi` to the `Event` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `Event` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Made the column `deskripsi` on table `Event` required. This step will fail if there are existing NULL values in that column.
  - Added the required column `bulan` to the `Invoice` table without a default value. This is not possible if the table is not empty.
  - Added the required column `tahun` to the `Invoice` table without a default value. This is not possible if the table is not empty.
  - Added the required column `totalTagihan` to the `Invoice` table without a default value. This is not possible if the table is not empty.
  - Added the required column `updatedAt` to the `Invoice` table without a default value. This is not possible if the table is not empty.
  - Added the required column `userId` to the `Invoice` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `Invoice` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `id` on the `Notification` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `userId` on the `Notification` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `buktiTransfer` to the `Payment` table without a default value. This is not possible if the table is not empty.
  - Added the required column `jumlah` to the `Payment` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `Payment` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `invoiceId` on the `Payment` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Changed the type of `userId` on the `Payment` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.
  - Added the required column `nik` to the `User` table without a default value. This is not possible if the table is not empty.
  - Changed the type of `id` on the `User` table. No cast exists, the column would be dropped and recreated, which cannot be done if there is data, since the column is required.

*/
-- AlterEnum
ALTER TYPE "Role" ADD VALUE 'PETUGAS_KEAMANAN';

-- DropForeignKey
ALTER TABLE "AssetLoan" DROP CONSTRAINT "AssetLoan_assetId_fkey";

-- DropForeignKey
ALTER TABLE "AssetLoan" DROP CONSTRAINT "AssetLoan_eventId_fkey";

-- DropForeignKey
ALTER TABLE "Attendance" DROP CONSTRAINT "Attendance_eventId_fkey";

-- DropForeignKey
ALTER TABLE "Attendance" DROP CONSTRAINT "Attendance_userId_fkey";

-- DropForeignKey
ALTER TABLE "BudgetItem" DROP CONSTRAINT "BudgetItem_requestId_fkey";

-- DropForeignKey
ALTER TABLE "BudgetRequest" DROP CONSTRAINT "BudgetRequest_eventId_fkey";

-- DropForeignKey
ALTER TABLE "BudgetRequest" DROP CONSTRAINT "BudgetRequest_userId_fkey";

-- DropForeignKey
ALTER TABLE "GuestLog" DROP CONSTRAINT "GuestLog_userId_fkey";

-- DropForeignKey
ALTER TABLE "Invoice" DROP CONSTRAINT "Invoice_unitId_fkey";

-- DropForeignKey
ALTER TABLE "LetterRequest" DROP CONSTRAINT "LetterRequest_userId_fkey";

-- DropForeignKey
ALTER TABLE "Notification" DROP CONSTRAINT "Notification_userId_fkey";

-- DropForeignKey
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_invoiceId_fkey";

-- DropForeignKey
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_userId_fkey";

-- DropForeignKey
ALTER TABLE "User" DROP CONSTRAINT "User_unitId_fkey";

-- DropIndex
DROP INDEX "Attendance_eventId_userId_key";

-- AlterTable
ALTER TABLE "Asset" DROP CONSTRAINT "Asset_pkey",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "kategori" TEXT NOT NULL,
ADD COLUMN     "stokTersedia" INTEGER NOT NULL,
ADD COLUMN     "stokTotal" INTEGER NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
ADD CONSTRAINT "Asset_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "AssetLoan" DROP CONSTRAINT "AssetLoan_pkey",
DROP COLUMN "eventId",
DROP COLUMN "peminjam",
DROP COLUMN "tglKembali",
DROP COLUMN "tglPinjam",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "jumlahPinjam" INTEGER NOT NULL,
ADD COLUMN     "tanggalMulai" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "tanggalSelesai" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "userId" UUID NOT NULL,
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
DROP COLUMN "assetId",
ADD COLUMN     "assetId" UUID NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'DIAJUKAN',
ADD CONSTRAINT "AssetLoan_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Attendance" DROP CONSTRAINT "Attendance_pkey",
DROP COLUMN "fotoPath",
DROP COLUMN "isMock",
DROP COLUMN "jarakM",
DROP COLUMN "lat",
DROP COLUMN "lng",
DROP COLUMN "metode",
DROP COLUMN "status",
ADD COLUMN     "fotoSelfie" TEXT NOT NULL,
ADD COLUMN     "isMocked" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "latitude" DOUBLE PRECISION NOT NULL,
ADD COLUMN     "longitude" DOUBLE PRECISION NOT NULL,
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
DROP COLUMN "eventId",
ADD COLUMN     "eventId" UUID NOT NULL,
DROP COLUMN "userId",
ADD COLUMN     "userId" UUID NOT NULL,
ADD CONSTRAINT "Attendance_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "CashLedger" DROP CONSTRAINT "CashLedger_pkey",
DROP COLUMN "kategori",
DROP COLUMN "refId",
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "deletedAt" TIMESTAMP(3),
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
DROP COLUMN "tipe",
ADD COLUMN     "tipe" TEXT NOT NULL,
ALTER COLUMN "jumlah" SET DATA TYPE DECIMAL(12,2),
ADD CONSTRAINT "CashLedger_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Event" DROP CONSTRAINT "Event_pkey",
DROP COLUMN "kategori",
DROP COLUMN "latCenter",
DROP COLUMN "lngCenter",
DROP COLUMN "radiusM",
DROP COLUMN "status",
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "lokasi" TEXT NOT NULL,
ADD COLUMN     "longitude" DOUBLE PRECISION,
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
ALTER COLUMN "deskripsi" SET NOT NULL,
ADD CONSTRAINT "Event_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Invoice" DROP CONSTRAINT "Invoice_pkey",
DROP COLUMN "jumlah",
DROP COLUMN "periode",
DROP COLUMN "unitId",
ADD COLUMN     "bulan" INTEGER NOT NULL,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "tahun" INTEGER NOT NULL,
ADD COLUMN     "totalTagihan" DECIMAL(12,2) NOT NULL,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL,
ADD COLUMN     "userId" UUID NOT NULL,
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
ADD CONSTRAINT "Invoice_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Notification" DROP CONSTRAINT "Notification_pkey",
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
DROP COLUMN "userId",
ADD COLUMN     "userId" UUID NOT NULL,
ADD CONSTRAINT "Notification_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "Payment" DROP CONSTRAINT "Payment_pkey",
DROP COLUMN "buktiPath",
ADD COLUMN     "buktiTransfer" TEXT NOT NULL,
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "jumlah" DECIMAL(12,2) NOT NULL,
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
DROP COLUMN "invoiceId",
ADD COLUMN     "invoiceId" UUID NOT NULL,
DROP COLUMN "userId",
ADD COLUMN     "userId" UUID NOT NULL,
ALTER COLUMN "status" SET DEFAULT 'PENDING',
ADD CONSTRAINT "Payment_pkey" PRIMARY KEY ("id");

-- AlterTable
ALTER TABLE "User" DROP CONSTRAINT "User_pkey",
DROP COLUMN "unitId",
ADD COLUMN     "blokRumah" TEXT,
ADD COLUMN     "deletedAt" TIMESTAMP(3),
ADD COLUMN     "fotoProfil" TEXT,
ADD COLUMN     "nik" VARCHAR(16) NOT NULL,
ADD COLUMN     "noRumah" TEXT,
ADD COLUMN     "rt" TEXT DEFAULT '05',
ADD COLUMN     "rw" TEXT DEFAULT '08',
DROP COLUMN "id",
ADD COLUMN     "id" UUID NOT NULL,
ADD CONSTRAINT "User_pkey" PRIMARY KEY ("id");

-- DropTable
DROP TABLE "BudgetItem";

-- DropTable
DROP TABLE "BudgetRequest";

-- DropTable
DROP TABLE "GuestLog";

-- DropTable
DROP TABLE "LetterRequest";

-- DropTable
DROP TABLE "Unit";

-- DropEnum
DROP TYPE "AttendanceStatus";

-- DropEnum
DROP TYPE "BudgetStatus";

-- DropEnum
DROP TYPE "CashType";

-- DropEnum
DROP TYPE "EventStatus";

-- DropEnum
DROP TYPE "LetterStatus";

-- CreateTable
CREATE TABLE "Letter" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "jenisSurat" TEXT NOT NULL,
    "keperluan" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'PENDING',
    "qrToken" TEXT,
    "filePdf" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Letter_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Guest" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "namaTamu" TEXT NOT NULL,
    "nikTamu" TEXT NOT NULL,
    "hubungan" TEXT NOT NULL,
    "tglMulai" TIMESTAMP(3) NOT NULL,
    "tglSelesai" TIMESTAMP(3) NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'MENGINAP',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "Guest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SosRequest" (
    "id" UUID NOT NULL,
    "userId" UUID NOT NULL,
    "kategori" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'MENUNGGU',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "SosRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "News" (
    "id" UUID NOT NULL,
    "authorId" UUID NOT NULL,
    "judul" TEXT NOT NULL,
    "konten" TEXT NOT NULL,
    "kategori" TEXT NOT NULL,
    "gambarUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "News_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Letter_qrToken_key" ON "Letter"("qrToken");

-- CreateIndex
CREATE UNIQUE INDEX "Attendance_userId_eventId_key" ON "Attendance"("userId", "eventId");

-- CreateIndex
CREATE UNIQUE INDEX "User_nik_key" ON "User"("nik");

-- AddForeignKey
ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_eventId_fkey" FOREIGN KEY ("eventId") REFERENCES "Event"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AssetLoan" ADD CONSTRAINT "AssetLoan_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "Asset"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AssetLoan" ADD CONSTRAINT "AssetLoan_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Letter" ADD CONSTRAINT "Letter_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Guest" ADD CONSTRAINT "Guest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SosRequest" ADD CONSTRAINT "SosRequest_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "News" ADD CONSTRAINT "News_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
