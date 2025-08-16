import React from 'react'
import PropTypes from 'prop-types'
import { useForm } from 'react-hook-form'
import { usersAPI } from '../services/api'
import { toast } from 'react-toastify'

const UserForm = ({ user, onSuccess, onCancel }) => {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting }
  } = useForm({
    defaultValues: user || { name: '', email: '' }
  })

  const onSubmit = async (data) => {
    try {
      if (user) {
        await usersAPI.update(user.id, data)
        toast.success('User updated successfully!')
      } else {
        await usersAPI.create(data)
        toast.success('User created successfully!')
      }
      onSuccess?.()
    } catch (error) {
      // Error is handled by axios interceptor
      console.error('Form submission error:', error)
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="user-form">
      <div className="form-group">
        <label htmlFor="name">Name *</label>
        <input
          id="name"
          type="text"
          {...register('name', {
            required: 'Name is required',
            minLength: {
              value: 2,
              message: 'Name must be at least 2 characters'
            },
            maxLength: {
              value: 50,
              message: 'Name must be less than 50 characters'
            }
          })}
          className={errors.name ? 'error' : ''}
        />
        {errors.name && <span className="error-text">{errors.name.message}</span>}
      </div>

      <div className="form-group">
        <label htmlFor="email">Email *</label>
        <input
          id="email"
          type="email"
          {...register('email', {
            required: 'Email is required',
            pattern: {
              value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
              message: 'Invalid email address'
            }
          })}
          className={errors.email ? 'error' : ''}
        />
        {errors.email && <span className="error-text">{errors.email.message}</span>}
      </div>

      <div className="form-actions">
        <button 
          type="submit" 
          disabled={isSubmitting}
          className="submit-button"
        >
          {isSubmitting ? 'Saving...' : (user ? 'Update' : 'Create')}
        </button>
        <button 
          type="button" 
          onClick={onCancel}
          className="cancel-button"
        >
          Cancel
        </button>
      </div>
    </form>
  )
}

UserForm.propTypes = {
  user: PropTypes.shape({
    id: PropTypes.number,
    name: PropTypes.string,
    email: PropTypes.string
  }),
  onSuccess: PropTypes.func.isRequired,
  onCancel: PropTypes.func.isRequired
}

UserForm.defaultProps = {
  user: null
}

export default UserForm
