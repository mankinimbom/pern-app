import Joi from 'joi'

// User validation schemas
export const createUserSchema = Joi.object({
  name: Joi.string().min(2).max(50).required().messages({
    'string.min': 'Name must be at least 2 characters long',
    'string.max': 'Name cannot exceed 50 characters',
    'any.required': 'Name is required'
  }),
  email: Joi.string().email().required().messages({
    'string.email': 'Please provide a valid email address',
    'any.required': 'Email is required'
  })
})

export const updateUserSchema = Joi.object({
  name: Joi.string().min(2).max(50).optional(),
  email: Joi.string().email().optional()
}).min(1)

// Post validation schemas
export const createPostSchema = Joi.object({
  title: Joi.string().min(3).max(200).required().messages({
    'string.min': 'Title must be at least 3 characters long',
    'string.max': 'Title cannot exceed 200 characters',
    'any.required': 'Title is required'
  }),
  content: Joi.string().min(10).max(5000).optional(),
  published: Joi.boolean().default(false)
})

export const updatePostSchema = Joi.object({
  title: Joi.string().min(3).max(200).optional(),
  content: Joi.string().min(10).max(5000).optional(),
  published: Joi.boolean().optional()
}).min(1)

// ID validation
export const idSchema = Joi.object({
  id: Joi.number().integer().positive().required()
})
