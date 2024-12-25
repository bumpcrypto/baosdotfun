-- CreateEnum
CREATE TYPE "BAOType" AS ENUM ('AGENT_FUND', 'CURATED_FUND');

-- CreateEnum
CREATE TYPE "BAOStatus" AS ENUM ('FUNDRAISING', 'COMING_SOON', 'ACTIVE', 'ENDED');

-- CreateEnum
CREATE TYPE "SeasonStatus" AS ENUM ('ACTIVE', 'UPCOMING', 'COMPLETED');

-- CreateEnum
CREATE TYPE "WhitelistStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "WhitelistTier" AS ENUM ('PROTOCOL_ENGAGEMENT', 'NFT_HOLDER', 'GENERAL_LOTTERY', 'STRATEGIC', 'STAKER');

-- CreateEnum
CREATE TYPE "AgentStatus" AS ENUM ('ACTIVE', 'PAUSED', 'OFFLINE');

-- CreateEnum
CREATE TYPE "AgentSpecialization" AS ENUM ('YIELD_FARMING', 'TRADING', 'LIQUIDITY_PROVISION', 'ARBITRAGE', 'GOVERNANCE');

-- CreateEnum
CREATE TYPE "Protocol" AS ENUM ('KODIAK', 'HONEY', 'MEME_SWAP', 'YEET', 'OOGA_BOOGA', 'INFRARED', 'BEX', 'CORE', 'DOLOMITE', 'STAKE_STONE', 'SHOGUN');

-- CreateEnum
CREATE TYPE "AnnouncementType" AS ENUM ('GENERAL', 'INVESTMENT', 'PERFORMANCE', 'TECHNICAL');

-- CreateEnum
CREATE TYPE "TransactionType" AS ENUM ('INVESTMENT', 'HARVEST', 'REBALANCE', 'GOVERNANCE', 'MULTISIG');

-- CreateTable
CREATE TABLE "BAO" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "BAOType" NOT NULL,
    "status" "BAOStatus" NOT NULL,
    "seasonId" INTEGER NOT NULL,
    "marketCap" DOUBLE PRECISION NOT NULL,
    "aum" DOUBLE PRECISION NOT NULL,
    "memberCount" INTEGER NOT NULL,
    "logo" TEXT NOT NULL,
    "bannerImage" TEXT,
    "description" TEXT NOT NULL,
    "isTestnet" BOOLEAN NOT NULL DEFAULT false,
    "tokenAddress" TEXT NOT NULL,
    "poolAddresses" TEXT[],
    "supportedBy" TEXT[],
    "farmProtocols" "Protocol"[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BAO_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Season" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "status" "SeasonStatus" NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "maxBAOs" INTEGER NOT NULL,

    CONSTRAINT "Season_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BAOAsset" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "tokenAddress" TEXT NOT NULL,
    "symbol" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "value" DOUBLE PRECISION NOT NULL,
    "lastUpdated" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BAOAsset_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BAOWhitelist" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" "WhitelistStatus" NOT NULL,
    "tier" "WhitelistTier" NOT NULL,
    "protocolActivity" DOUBLE PRECISION,
    "yapActivity" DOUBLE PRECISION,
    "nftHoldings" TEXT[],
    "beraBalance" DOUBLE PRECISION,
    "hasTransaction" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BAOWhitelist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BAOStaking" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "stakerAddress" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endTime" TIMESTAMP(3),
    "rewards" DOUBLE PRECISION NOT NULL DEFAULT 0,

    CONSTRAINT "BAOStaking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BAOAgent" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "profilePic" TEXT NOT NULL,
    "characterBio" TEXT NOT NULL,
    "status" "AgentStatus" NOT NULL DEFAULT 'PAUSED',
    "specializations" "AgentSpecialization"[],
    "publicKey" TEXT NOT NULL,
    "encryptedKey" TEXT NOT NULL,
    "gnosisSafe" TEXT NOT NULL,
    "safeThreshold" INTEGER NOT NULL,
    "safeOwners" TEXT[],
    "plugins" JSONB NOT NULL,
    "performanceData" JSONB,
    "lastActive" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BAOAgent_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TeamMember" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "profilePic" TEXT NOT NULL,
    "address" TEXT NOT NULL,
    "twitter" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TeamMember_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Announcement" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "type" "AnnouncementType" NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "authorId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Announcement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Transaction" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "type" "TransactionType" NOT NULL,
    "txHash" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "token" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ChatMessage" (
    "id" TEXT NOT NULL,
    "baoId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "agentId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "isAgent" BOOLEAN NOT NULL DEFAULT false,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ChatMessage_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "BAO_seasonId_idx" ON "BAO"("seasonId");

-- CreateIndex
CREATE INDEX "BAOAsset_baoId_idx" ON "BAOAsset"("baoId");

-- CreateIndex
CREATE INDEX "BAOWhitelist_baoId_idx" ON "BAOWhitelist"("baoId");

-- CreateIndex
CREATE INDEX "BAOWhitelist_userId_idx" ON "BAOWhitelist"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "BAOWhitelist_baoId_userId_key" ON "BAOWhitelist"("baoId", "userId");

-- CreateIndex
CREATE INDEX "BAOStaking_userId_idx" ON "BAOStaking"("userId");

-- CreateIndex
CREATE INDEX "BAOStaking_stakerAddress_idx" ON "BAOStaking"("stakerAddress");

-- CreateIndex
CREATE UNIQUE INDEX "User_address_key" ON "User"("address");

-- CreateIndex
CREATE INDEX "BAOAgent_baoId_idx" ON "BAOAgent"("baoId");

-- CreateIndex
CREATE INDEX "TeamMember_baoId_idx" ON "TeamMember"("baoId");

-- CreateIndex
CREATE INDEX "Announcement_baoId_idx" ON "Announcement"("baoId");

-- CreateIndex
CREATE INDEX "Announcement_authorId_idx" ON "Announcement"("authorId");

-- CreateIndex
CREATE INDEX "Transaction_baoId_idx" ON "Transaction"("baoId");

-- CreateIndex
CREATE INDEX "Transaction_txHash_idx" ON "Transaction"("txHash");

-- CreateIndex
CREATE INDEX "ChatMessage_baoId_idx" ON "ChatMessage"("baoId");

-- CreateIndex
CREATE INDEX "ChatMessage_userId_idx" ON "ChatMessage"("userId");

-- CreateIndex
CREATE INDEX "ChatMessage_agentId_idx" ON "ChatMessage"("agentId");

-- AddForeignKey
ALTER TABLE "BAO" ADD CONSTRAINT "BAO_seasonId_fkey" FOREIGN KEY ("seasonId") REFERENCES "Season"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BAOAsset" ADD CONSTRAINT "BAOAsset_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BAOWhitelist" ADD CONSTRAINT "BAOWhitelist_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BAOWhitelist" ADD CONSTRAINT "BAOWhitelist_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BAOStaking" ADD CONSTRAINT "BAOStaking_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BAOAgent" ADD CONSTRAINT "BAOAgent_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TeamMember" ADD CONSTRAINT "TeamMember_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Announcement" ADD CONSTRAINT "Announcement_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Announcement" ADD CONSTRAINT "Announcement_authorId_fkey" FOREIGN KEY ("authorId") REFERENCES "TeamMember"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_baoId_fkey" FOREIGN KEY ("baoId") REFERENCES "BAO"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ChatMessage" ADD CONSTRAINT "ChatMessage_agentId_fkey" FOREIGN KEY ("agentId") REFERENCES "BAOAgent"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
