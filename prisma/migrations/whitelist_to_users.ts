import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function migrateWhitelistToUsers() {
  try {
    console.log('Starting migration of whitelist entries to users...')
    
    // Get all whitelist entries
    const whitelistEntries = await prisma.whitelistEntry.findMany()
    console.log(`Found ${whitelistEntries.length} whitelist entries to migrate`)
    
    // Create users for each whitelist entry
    for (const entry of whitelistEntries) {
      // Check if user already exists with this address
      const existingUser = await prisma.user.findUnique({
        where: { address: entry.address }
      })
      
      if (!existingUser) {
        // Create new user if doesn't exist
        await prisma.user.create({
          data: {
            address: entry.address,
            // We use cuid() for id generation as specified in our schema
            // Prisma will handle this automatically
          }
        })
        console.log(`Created new user for address: ${entry.address}`)
      } else {
        console.log(`User already exists for address: ${entry.address}`)
      }
    }
    
    console.log('Migration completed successfully!')
    
  } catch (error) {
    console.error('Error during migration:', error)
    throw error
  } finally {
    await prisma.$disconnect()
  }
}

// Run the migration
migrateWhitelistToUsers()
  .catch((error) => {
    console.error('Migration failed:', error)
    process.exit(1)
  }) 