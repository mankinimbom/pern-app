import { render, screen } from '@testing-library/react'
import { QueryClient, QueryClientProvider } from 'react-query'
import App from '../App'

// Create a test query client
const createTestQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
    },
  },
})

const renderWithProviders = (ui, options = {}) => {
  const queryClient = createTestQueryClient()
  
  const AllTheProviders = ({ children }) => (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  )

  return render(ui, { wrapper: AllTheProviders, ...options })
}

describe('App Component', () => {
  it('renders without crashing', () => {
    renderWithProviders(<App />)
    expect(screen.getByText('PERN Stack Application')).toBeInTheDocument()
  })

  it('shows the main heading', () => {
    renderWithProviders(<App />)
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('PERN Stack Application')
  })

  it('shows the subtitle', () => {
    renderWithProviders(<App />)
    expect(screen.getByText('Production-ready deployment with GitOps')).toBeInTheDocument()
  })
})
