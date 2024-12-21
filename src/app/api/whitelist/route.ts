import { NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { telegram, twitter, address } = body;

    // Validate input
    if (!telegram || !twitter || !address) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      );
    }

    // Create whitelist entry
    const entry = await prisma.whitelistEntry.create({
      data: {
        telegram,
        twitter,
        address,
      },
    });

    return NextResponse.json(entry);
  } catch (error: any) {
    if (error.code === 'P2002') {
      return NextResponse.json(
        { error: 'Address already whitelisted' },
        { status: 400 }
      );
    }
    
    console.error('Error creating whitelist entry:', error);
    return NextResponse.json(
      { error: 'Error creating whitelist entry' },
      { status: 500 }
    );
  }
} 