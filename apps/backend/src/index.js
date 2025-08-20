import { PrismaClient } from '@prisma/client'
import compression from 'compression'
import RedisStore from 'connect-redis'
import cors from 'cors'
import dotenv from 'dotenv'
import express from 'express'
import rateLimit from 'express-rate-limit'
import session from 'express-session'
import helmet from 'helmet'
import morgan from 'morgan'
import { createClient } from 'redis'

// Test CI/CD pipeline - backend image tag update verification
// Import custom middleware and config
import logger from './config/logger.js'
import { asyncHandler, errorHandler, notFoundHandler, validate } from './middleware/errorHandler.js'
import {
    createPostSchema,
    createUserSchema,
    idSchema,
    updateUserSchema
} from './validation/schemas.js'

dotenv.config()

const app = express()
const prisma = new PrismaClient({
  log: ['query', 'info', 'warn', 'error'],
})
const PORT = process.env.PORT || 3001

// Redis client setup
let redisClient
if (process.env.REDIS_URL) {
  redisClient = createClient({
    url: process.env.REDIS_URL
  })
  redisClient.on('error', (err) => logger.error('Redis Client Error', err))
  redisClient.connect().catch(logger.error)
}

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
}))

// CORS setup
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'http://localhost:5173',
  credentials: true,
  optionsSuccessStatus: 200
}))

app.use(compression())

// Request logging
app.use(morgan('combined', {
  stream: { write: message => logger.http(message.trim()) }
}))

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
  message: {
    error: 'Too many requests from this IP, please try again later.',
    retryAfter: Math.ceil((parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 900000) / 1000)
  },
  standardHeaders: true,
  legacyHeaders: false,
})
app.use(limiter)

// Session middleware
if (redisClient) {
  app.use(session({
    store: new RedisStore({ client: redisClient }),
    secret: process.env.JWT_SECRET || 'your-secret-key',
    resave: false,
    saveUninitialized: false,
    cookie: {
      secure: process.env.NODE_ENV === 'production',
      httpOnly: true,
      maxAge: 1000 * 60 * 60 * 24 // 24 hours
    }
  }))
}

// Body parsing middleware
app.use(express.json({ limit: '10mb' }))
app.use(express.urlencoded({ extended: true }))

// Health check endpoints
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    version: process.env.npm_package_version || '1.0.0'
  })
})

app.get('/ready', asyncHandler(async (req, res) => {
  try {
    // Check database connection
    await prisma.$queryRaw`SELECT 1`
    
    // Check Redis connection if available
    let redisStatus = 'not configured'
    if (redisClient) {
      redisStatus = redisClient.isReady ? 'connected' : 'disconnected'
    }
    
    res.status(200).json({ 
      status: 'ready', 
      timestamp: new Date().toISOString(),
      services: {
        database: 'connected',
        redis: redisStatus
      }
    })
  } catch (error) {
    logger.error('Readiness check failed:', error)
    res.status(503).json({ 
      status: 'not ready', 
      error: error.message,
      timestamp: new Date().toISOString()
    })
  }
}))

// API routes with validation
app.get('/users', asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, search } = req.query
  const offset = (page - 1) * limit
  
  const where = search ? {
    OR: [
      { name: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } }
    ]
  } : {}
  
  const [users, total] = await Promise.all([
    prisma.user.findMany({
      where,
      include: { posts: true },
      skip: offset,
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    }),
    prisma.user.count({ where })
  ])
  
  res.json({
    users,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      pages: Math.ceil(total / limit)
    }
  })
}))

app.post('/users', validate(createUserSchema), asyncHandler(async (req, res) => {
  const { name, email } = req.body
  
  // Check if user already exists
  const existingUser = await prisma.user.findUnique({ where: { email } })
  if (existingUser) {
    return res.status(409).json({
      error: {
        message: 'User with this email already exists',
        field: 'email'
      }
    })
  }
  
  const user = await prisma.user.create({
    data: { name, email },
    include: { posts: true }
  })
  
  logger.info('User created:', { userId: user.id, email: user.email })
  res.status(201).json(user)
}))

app.get('/users/:id', validate(idSchema, 'params'), asyncHandler(async (req, res) => {
  const { id } = req.params
  const user = await prisma.user.findUnique({
    where: { id: parseInt(id) },
    include: { posts: true }
  })
  
  if (!user) {
    return res.status(404).json({ 
      error: { 
        message: 'User not found',
        id: parseInt(id)
      } 
    })
  }
  
  res.json(user)
}))

app.put('/users/:id', 
  validate(idSchema, 'params'),
  validate(updateUserSchema),
  asyncHandler(async (req, res) => {
    const { id } = req.params
    const updateData = req.body
    
    // Check if user exists
    const existingUser = await prisma.user.findUnique({ where: { id: parseInt(id) } })
    if (!existingUser) {
      return res.status(404).json({ 
        error: { 
          message: 'User not found',
          id: parseInt(id)
        } 
      })
    }
    
    // Check email uniqueness if email is being updated
    if (updateData.email && updateData.email !== existingUser.email) {
      const emailExists = await prisma.user.findUnique({ where: { email: updateData.email } })
      if (emailExists) {
        return res.status(409).json({
          error: {
            message: 'User with this email already exists',
            field: 'email'
          }
        })
      }
    }
    
    const user = await prisma.user.update({
      where: { id: parseInt(id) },
      data: updateData,
      include: { posts: true }
    })
    
    logger.info('User updated:', { userId: user.id })
    res.json(user)
  })
)

app.delete('/users/:id', validate(idSchema, 'params'), asyncHandler(async (req, res) => {
  const { id } = req.params
  
  const user = await prisma.user.findUnique({ where: { id: parseInt(id) } })
  if (!user) {
    return res.status(404).json({ 
      error: { 
        message: 'User not found',
        id: parseInt(id)
      } 
    })
  }
  
  await prisma.user.delete({ where: { id: parseInt(id) } })
  
  logger.info('User deleted:', { userId: parseInt(id) })
  res.status(204).send()
}))

// Posts endpoints
app.get('/posts', asyncHandler(async (req, res) => {
  const { page = 1, limit = 10, published } = req.query
  const offset = (page - 1) * limit
  
  const where = published !== undefined ? { published: published === 'true' } : {}
  
  const [posts, total] = await Promise.all([
    prisma.post.findMany({
      where,
      include: { author: true },
      skip: offset,
      take: parseInt(limit),
      orderBy: { createdAt: 'desc' }
    }),
    prisma.post.count({ where })
  ])
  
  res.json({
    posts,
    pagination: {
      page: parseInt(page),
      limit: parseInt(limit),
      total,
      pages: Math.ceil(total / limit)
    }
  })
}))

app.post('/users/:id/posts', 
  validate(idSchema, 'params'),
  validate(createPostSchema),
  asyncHandler(async (req, res) => {
    const { id } = req.params
    const { title, content, published } = req.body
    
    // Check if user exists
    const user = await prisma.user.findUnique({ where: { id: parseInt(id) } })
    if (!user) {
      return res.status(404).json({ 
        error: { 
          message: 'User not found',
          id: parseInt(id)
        } 
      })
    }
    
    const post = await prisma.post.create({
      data: {
        title,
        content,
        published: published || false,
        authorId: parseInt(id)
      },
      include: { author: true }
    })
    
    logger.info('Post created:', { postId: post.id, authorId: parseInt(id) })
    res.status(201).json(post)
  })
)

// Error handling middleware (must be last)
app.use(notFoundHandler)
app.use(errorHandler)

// Graceful shutdown
const gracefulShutdown = async (signal) => {
  logger.info(`Received ${signal}, shutting down gracefully...`)
  
  try {
    await prisma.$disconnect()
    if (redisClient) {
      await redisClient.disconnect()
    }
    logger.info('Graceful shutdown completed')
    process.exit(0)
  } catch (error) {
    logger.error('Error during shutdown:', error)
    process.exit(1)
  }
}

process.on('SIGINT', () => gracefulShutdown('SIGINT'))
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  logger.error('Unhandled Rejection at:', promise, 'reason:', reason)
  process.exit(1)
})

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception:', error)
  process.exit(1)
})

app.listen(PORT, '0.0.0.0', () => {
  logger.info(`Server running on port ${PORT}`)
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`)
})
