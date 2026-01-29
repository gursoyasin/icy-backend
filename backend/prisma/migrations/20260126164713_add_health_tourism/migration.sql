-- CreateTable
CREATE TABLE "Transfer" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "pickupTime" DATETIME NOT NULL,
    "pickupLocation" TEXT NOT NULL,
    "dropoffLocation" TEXT NOT NULL,
    "driverName" TEXT,
    "plateNumber" TEXT,
    "status" TEXT NOT NULL DEFAULT 'scheduled',
    "patientId" TEXT NOT NULL,
    CONSTRAINT "Transfer_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "Patient" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Accommodation" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "hotelName" TEXT NOT NULL,
    "checkInDate" DATETIME NOT NULL,
    "checkOutDate" DATETIME NOT NULL,
    "roomType" TEXT,
    "status" TEXT NOT NULL DEFAULT 'booked',
    "patientId" TEXT NOT NULL,
    CONSTRAINT "Accommodation_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "Patient" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
