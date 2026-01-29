-- CreateTable
CREATE TABLE "PhotoEntry" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "beforeUrl" TEXT,
    "afterUrl" TEXT,
    "date" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "notes" TEXT,
    "patientId" TEXT NOT NULL,
    CONSTRAINT "PhotoEntry_patientId_fkey" FOREIGN KEY ("patientId") REFERENCES "Patient" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
