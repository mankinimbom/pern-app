import { useState, useEffect } from 'react'
import { QueryClient, QueryClientProvider, useQuery, useQueryClient } from 'react-query'
import { ToastContainer } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'

import ErrorBoundary from './components/ErrorBoundary'
import LoadingSpinner from './components/LoadingSpinner'
import UserForm from './components/UserForm'
import { usersAPI, healthAPI } from './services/api'
import './App.css'

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 2,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
  },
})

// Users List Component
const UsersList = () => {
  const [showForm, setShowForm] = useState(false)
  const [editingUser, setEditingUser] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [currentPage, setCurrentPage] = useState(1)
  
  const queryClient = useQueryClient()

  const { 
    data: usersData, 
    isLoading, 
    error,
    refetch 
  } = useQuery(
    ['users', { page: currentPage, search: searchTerm }],
    () => usersAPI.getAll({ 
      page: currentPage, 
      limit: 10, 
      search: searchTerm || undefined 
    }),
    {
      select: (response) => response.data,
      keepPreviousData: true,
    }
  )

  const { data: healthData } = useQuery(
    'health',
    () => healthAPI.check(),
    {
      select: (response) => response.data,
      refetchInterval: 30000, // Check every 30 seconds
    }
  )

  const handleFormSuccess = () => {
    setShowForm(false)
    setEditingUser(null)
    queryClient.invalidateQueries('users')
  }

  const handleEdit = (user) => {
    setEditingUser(user)
    setShowForm(true)
  }

  const handleDelete = async (userId) => {
    if (window.confirm('Are you sure you want to delete this user?')) {
      try {
        await usersAPI.delete(userId)
        queryClient.invalidateQueries('users')
      } catch (error) {
        console.error('Delete error:', error)
      }
    }
  }

  const handleSearch = (e) => {
    setSearchTerm(e.target.value)
    setCurrentPage(1) // Reset to first page when searching
  }

  if (error) {
    return (
      <div className="error-container">
        <h2>Error Loading Users</h2>
        <p>{error.message}</p>
        <button onClick={() => refetch()} className="retry-button">
          Try Again
        </button>
      </div>
    )
  }

  const users = usersData?.users || []
  const pagination = usersData?.pagination

  return (
    <div className="users-container">
      <div className="header">
        <h2>Users Management</h2>
        <div className="header-actions">
          {healthData && (
            <div className={`health-indicator ${healthData.status}`}>
              <span className="status-dot"></span>
              {healthData.status}
            </div>
          )}
          <button 
            onClick={() => setShowForm(true)}
            className="add-button"
          >
            Add User
          </button>
        </div>
      </div>

      <div className="search-container">
        <input
          type="text"
          placeholder="Search users..."
          value={searchTerm}
          onChange={handleSearch}
          className="search-input"
        />
      </div>

      {showForm && (
        <div className="modal-overlay">
          <div className="modal">
            <h3>{editingUser ? 'Edit User' : 'Add New User'}</h3>
            <UserForm
              user={editingUser}
              onSuccess={handleFormSuccess}
              onCancel={() => {
                setShowForm(false)
                setEditingUser(null)
              }}
            />
          </div>
        </div>
      )}

      {isLoading ? (
        <LoadingSpinner size="large" message="Loading users..." />
      ) : (
        <>
          <div className="users-grid">
            {users.length === 0 ? (
              <p className="empty-state">No users found</p>
            ) : (
              users.map(user => (
                <div key={user.id} className="user-card">
                  <div className="user-info">
                    <h3>{user.name}</h3>
                    <p>{user.email}</p>
                    <p className="post-count">{user.posts?.length || 0} posts</p>
                    <p className="created-date">
                      Joined: {new Date(user.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="user-actions">
                    <button 
                      onClick={() => handleEdit(user)}
                      className="edit-button"
                    >
                      Edit
                    </button>
                    <button 
                      onClick={() => handleDelete(user.id)}
                      className="delete-button"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              ))
            )}
          </div>

          {pagination && pagination.pages > 1 && (
            <div className="pagination">
              <button 
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage === 1}
                className="page-button"
              >
                Previous
              </button>
              
              <span className="page-info">
                Page {currentPage} of {pagination.pages} 
                ({pagination.total} total users)
              </span>
              
              <button 
                onClick={() => setCurrentPage(p => Math.min(pagination.pages, p + 1))}
                disabled={currentPage === pagination.pages}
                className="page-button"
              >
                Next
              </button>
            </div>
          )}
        </>
      )}
    </div>
  )
}

// Main App Component
function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ErrorBoundary>
        <div className="App">
          <header className="App-header">
            <h1>PERN Stack Application</h1>
            <p>Production-ready deployment with GitOps</p>
          </header>
          
          <main className="App-main">
            <UsersList />
          </main>
          
          <ToastContainer
            position="top-right"
            autoClose={5000}
            hideProgressBar={false}
            newestOnTop={false}
            closeOnClick
            rtl={false}
            pauseOnFocusLoss
            draggable
            pauseOnHover
          />
        </div>
      </ErrorBoundary>
    </QueryClientProvider>
  )
}

export default App
