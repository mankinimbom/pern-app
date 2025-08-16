import { execSync } from 'child_process'

// Set test database URL before importing Prisma
process.env.DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/pern_test'

import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

beforeAll(async () => {
  // Run migrations
  execSync('npx prisma migrate deploy', { stdio: 'inherit' })
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
