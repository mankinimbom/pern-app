import { execSync } from 'child_process'
import dotenv from 'dotenv'

// Load test environment variables
dotenv.config({ path: '.env.test' })

// Set test database URL before importing Prisma
// Use the same database name as configured in GitHub Actions (testdb)
process.env.DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/testdb'

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

beforeAll(async () => {
  // Generate Prisma client and push database schema
  try {
    console.log('Setting up test database...')
    
    // Wait a bit for PostgreSQL service to be ready
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    // Test database connection
    console.log('Testing database connection...')
    await prisma.$connect()
    
    console.log('Generating Prisma client...')
    execSync('npx prisma generate', { stdio: 'inherit' })
    
    console.log('Pushing database schema...')
    execSync('npx prisma db push --force-reset', { stdio: 'inherit' })
    
    console.log('Database setup completed successfully')
  } catch (error) {
    console.error('Failed to set up database:', error)
    console.error('Error details:', error.message)
    console.error('Database URL:', process.env.DATABASE_URL)
    process.exit(1)
  }
})

beforeEach(async () => {
  // Clean up database before each test
  await prisma.post.deleteMany()
  await prisma.user.deleteMany()
})

afterAll(async () => {
  await prisma.$disconnect()
})

export { prisma }
