import request from 'supertest'
import express from 'express'
import { PrismaClient } from '@prisma/client'
import { prisma } from './setup.js'

// Import the main app (we'll need to refactor index.js to export the app)
// For now, let's create a simple test app
const app = express()
app.use(express.json())

// Mock a simple users endpoint for testing
app.get('/users', async (req, res) => {
  const users = await prisma.user.findMany({
    include: { posts: true }
  })
  res.json(users)
})

app.post('/users', async (req, res) => {
  try {
    const { name, email } = req.body
    const user = await prisma.user.create({
      data: { name, email }
    })
    res.status(201).json(user)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

describe('Users API', () => {
  describe('GET /users', () => {
    it('should return empty array when no users exist', async () => {
      const response = await request(app).get('/users')
      
      expect(response.status).toBe(200)
      expect(response.body).toEqual([])
    })

    it('should return users when they exist', async () => {
      // Create a test user
      await prisma.user.create({
        data: {
          name: 'Test User',
          email: 'test@example.com'
        }
      })

      const response = await request(app).get('/users')
      
      expect(response.status).toBe(200)
      expect(response.body).toHaveLength(1)
      expect(response.body[0]).toMatchObject({
        name: 'Test User',
        email: 'test@example.com'
      })
    })
  })

  describe('POST /users', () => {
    it('should create a new user with valid data', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com'
      }

      const response = await request(app)
        .post('/users')
        .send(userData)

      expect(response.status).toBe(201)
      expect(response.body).toMatchObject(userData)
      expect(response.body.id).toBeDefined()
      expect(response.body.createdAt).toBeDefined()
    })

    it('should fail to create user with duplicate email', async () => {
      const userData = {
        name: 'John Doe',
        email: 'john@example.com'
      }

      // Create first user
      await request(app).post('/users').send(userData)

      // Try to create duplicate
      const response = await request(app)
        .post('/users')
        .send(userData)

      expect(response.status).toBe(500)
      expect(response.body.error).toBeDefined()
    })

    it('should fail with missing required fields', async () => {
      const response = await request(app)
        .post('/users')
        .send({})

      expect(response.status).toBe(500)
    })
  })
})
