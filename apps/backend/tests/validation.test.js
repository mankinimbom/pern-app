import { createUserSchema, idSchema } from '../src/validation/schemas.js'

describe('Validation Schemas', () => {
  describe('createUserSchema', () => {
    it('should validate correct user data', () => {
      const validData = {
        name: 'John Doe',
        email: 'john@example.com'
      }

      const { error } = createUserSchema.validate(validData)
      expect(error).toBeUndefined()
    })

    it('should reject invalid email', () => {
      const invalidData = {
        name: 'John Doe',
        email: 'invalid-email'
      }

      const { error } = createUserSchema.validate(invalidData)
      expect(error).toBeDefined()
      expect(error.details[0].path).toContain('email')
    })

    it('should reject short name', () => {
      const invalidData = {
        name: 'J',
        email: 'john@example.com'
      }

      const { error } = createUserSchema.validate(invalidData)
      expect(error).toBeDefined()
      expect(error.details[0].path).toContain('name')
    })

    it('should require name and email', () => {
      const invalidData = {}

      const { error } = createUserSchema.validate(invalidData, { abortEarly: false })
      expect(error).toBeDefined()
      expect(error.details).toHaveLength(2)
    })
  })

  describe('idSchema', () => {
    it('should validate positive integer ID', () => {
      const validData = { id: 123 }
      const { error } = idSchema.validate(validData)
      expect(error).toBeUndefined()
    })

    it('should reject negative ID', () => {
      const invalidData = { id: -1 }
      const { error } = idSchema.validate(invalidData)
      expect(error).toBeDefined()
    })

    it('should reject non-integer ID', () => {
      const invalidData = { id: 'abc' }
      const { error } = idSchema.validate(invalidData)
      expect(error).toBeDefined()
    })
  })
})
