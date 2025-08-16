import { useState, useEffect } from 'react'
import axios from 'axios'
import './App.css'

function App() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchUsers()
  }, [])

  const fetchUsers = async () => {
    try {
      const response = await axios.get('/api/users')
      setUsers(response.data)
    } catch (error) {
      console.error('Error fetching users:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="App">
      <header className="App-header">
        <h1>PERN Stack Application</h1>
        <p>Production-ready deployment with GitOps</p>
        
        {loading ? (
          <p>Loading users...</p>
        ) : (
          <div>
            <h2>Users ({users.length})</h2>
            {users.length === 0 ? (
              <p>No users found</p>
            ) : (
              <ul>
                {users.map(user => (
                  <li key={user.id}>{user.name} ({user.email})</li>
                ))}
              </ul>
            )}
          </div>
        )}
      </header>
    </div>
  )
}

export default App
