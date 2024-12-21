import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

// PrismaClient is attached to the `global` object in development to prevent
// exhausting your database connection limit.
const globalForPrisma = global as unknown as { prisma: PrismaClient };

export const prisma = globalForPrisma.prisma || new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const address = searchParams.get('address');

  if (!address) {
    return NextResponse.json({ error: 'Address is required' }, { status: 400 });
  }

  try {
    const existingEntry = await prisma.whitelistEntry.findUnique({
      where: { address },
    });

    return NextResponse.json({ exists: !!existingEntry });
  } catch (error) {
    console.error('Error checking address:', error);
    return NextResponse.json({ error: 'Error checking address' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { telegram, twitter, address, wantsToStartBao } = body;

    // Validate Ethereum address
    if (!address || !/^0x[a-fA-F0-9]{40}$/.test(address)) {
      return NextResponse.json({ error: 'Invalid Ethereum address' }, { status: 400 });
    }

    // Check for duplicate address
    const existingEntry = await prisma.whitelistEntry.findUnique({
      where: { address },
    });

    if (existingEntry) {
      return NextResponse.json({ error: 'Address already whitelisted' }, { status: 400 });
    }

    // Create new whitelist entry
    const entry = await prisma.whitelistEntry.create({
      data: {
        telegram,
        twitter,
        address,
        wantsToStartBao: wantsToStartBao || false,
      },
    });

    return NextResponse.json(entry);
  } catch (error) {
    console.error('Error creating whitelist entry:', error);
    if (error instanceof Error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }
    return NextResponse.json({ error: 'Error creating whitelist entry' }, { status: 500 });
  }
} 