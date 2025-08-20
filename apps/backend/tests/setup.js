import { execSync } from 'child_process'
import dotenv from 'dotenv'

// Load test environment variables
dotenv.config({ path: '.env.test' })

// Set test database URL before importing Prisma
// Use the same credentials as configured in GitHub Actions
process.env.DATABASE_URL = process.env.DATABASE_URL || 'postgresql://testuser:testpass@localhost:5432/testdb'

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

beforeAll(async () => {
  // Generate Prisma client and push database schema
  try {
    console.log('Setting up test database...')
    console.log('Database URL:', process.env.DATABASE_URL)
    
    // Wait a bit for PostgreSQL service to be ready
    await new Promise(resolve => setTimeout(resolve, 3000))
    
    // Generate Prisma client first
    console.log('Generating Prisma client...')
    execSync('npx prisma generate', { stdio: 'inherit' })
    
    // Test database connection with retries
    console.log('Testing database connection...')
    let connected = false
    for (let i = 0; i < 5; i++) {
      try {
        await prisma.$connect()
        connected = true
        console.log('Database connection successful')
        break
      } catch (connError) {
        console.log(`Connection attempt ${i + 1}/5 failed, retrying...`)
        await new Promise(resolve => setTimeout(resolve, 2000))
      }
    }
    
    if (!connected) {
      throw new Error('Could not connect to database after 5 attempts')
    }
    
    console.log('Pushing database schema...')
    execSync('npx prisma db push --force-reset', { stdio: 'inherit' })
    
    console.log('Database setup completed successfully')
  } catch (error) {
    console.error('Failed to set up database:', error)
    console.error('Error details:', error.message)
    console.error('Database URL:', process.env.DATABASE_URL)
    // Don't exit in CI environment, let tests fail gracefully
    if (process.env.CI) {
      console.warn('Skipping database setup in CI environment')
    } else {
      process.exit(1)
    }
  }
}, 60000)

beforeEach(async () => {
  // Clean up database before each test
  try {
    await prisma.post.deleteMany()
    await prisma.user.deleteMany()
  } catch (error) {
    console.warn('Database cleanup failed:', error.message)
  }
})

afterAll(async () => {
  try {
    await prisma.$disconnect()
  } catch (error) {
    console.warn('Database disconnect failed:', error.message)
  }
})

export { prisma }
