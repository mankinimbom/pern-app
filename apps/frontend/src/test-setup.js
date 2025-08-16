import '@testing-library/jest-dom'

// Mock fetch globally
global.fetch = vi.fn()

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
}
global.localStorage = localStorageMock

// Mock window.confirm
global.confirm = vi.fn(() => true)

// Clean up after each test
afterEach(() => {
  vi.clearAllMocks()
})
