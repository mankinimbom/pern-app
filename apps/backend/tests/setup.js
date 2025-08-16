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
    execSync('npx prisma generate', { stdio: 'inherit' })
    execSync('npx prisma db push --force-reset', { stdio: 'inherit' })
  } catch (error) {
    console.error('Failed to set up database:', error)
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
