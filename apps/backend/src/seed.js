import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  // eslint-disable-next-line no-console
  console.log('Seeding database...')
  
  // Create users
  const user1 = await prisma.user.create({
    data: {
      name: 'John Doe',
      email: 'john@example.com',
      posts: {
        create: [
          {
            title: 'Hello World',
            content: 'This is my first post!',
            published: true
          }
        ]
      }
    }
  })

  const user2 = await prisma.user.create({
    data: {
      name: 'Jane Smith',
      email: 'jane@example.com',
      posts: {
        create: [
          {
            title: 'Getting Started',
            content: 'Welcome to our PERN stack application!',
            published: true
          }
        ]
      }
    }
  })

  // eslint-disable-next-line no-console
  console.log('Database seeded successfully!')
  // eslint-disable-next-line no-console
  console.log({ user1, user2 })
}

main()
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
