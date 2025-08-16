import { PrismaClient } from '@prisma/client'
import { execSync } from 'child_process'

const prisma = new PrismaClient()

beforeAll(async () => {
  // Set test database URL
  process.env.DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/pern_test'
  
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
