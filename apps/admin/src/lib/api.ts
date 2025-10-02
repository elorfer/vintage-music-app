import axios from 'axios';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export const api = axios.create({
  baseURL: `${API_BASE_URL}/api/v1`,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor para agregar el token de autenticación
api.interceptors.request.use(
  (config) => {
    if (typeof window !== 'undefined') {
      const token = localStorage.getItem('access_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor para manejar errores
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token expirado o inválido
      if (typeof window !== 'undefined') {
        localStorage.removeItem('access_token');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// Funciones de utilidad para la API
export const apiClient = {
  // Auth
  login: (email: string, password: string) =>
    api.post('/auth/login', { email, password }),
  
  logout: () => api.post('/auth/logout'),
  
  getProfile: () => api.get('/auth/profile'),

  // Users
  getUsers: (page = 1, limit = 10) =>
    api.get(`/users?page=${page}&limit=${limit}`),
  
  getUser: (id: string) => api.get(`/users/${id}`),
  
  updateUser: (id: string, data: any) => api.patch(`/users/${id}`, data),
  
  deleteUser: (id: string) => api.delete(`/users/${id}`),
  
  activateUser: (id: string) => api.post(`/users/${id}/activate`),
  
  deactivateUser: (id: string) => api.post(`/users/${id}/deactivate`),
  
  verifyUser: (id: string) => api.post(`/users/${id}/verify`),

  // Artists
  getArtists: (page = 1, limit = 10) =>
    api.get(`/artists?page=${page}&limit=${limit}`),
  
  getArtist: (id: string) => api.get(`/artists/${id}`),
  
  getArtistStats: (id: string) => api.get(`/artists/${id}/stats`),
  
  verifyArtist: (id: string) => api.patch(`/artists/${id}/verify`),

  // Songs
  getSongs: (page = 1, limit = 10) =>
    api.get(`/songs?page=${page}&limit=${limit}`),
  
  getSong: (id: string) => api.get(`/songs/${id}`),
  
  getTopSongsByPlays: (limit = 10) => api.get(`/songs/top?limit=${limit}`),

  // Playlists
  getPlaylists: (page = 1, limit = 10) =>
    api.get(`/playlists?page=${page}&limit=${limit}`),
  
  getPlaylist: (id: string) => api.get(`/playlists/${id}`),

  // Analytics
  getGlobalStats: () => api.get('/analytics/global'),
  
  getTopArtists: (limit = 10) => api.get(`/analytics/top-artists?limit=${limit}`),
  
  getTopSongs: (limit = 10) => api.get(`/analytics/top-songs?limit=${limit}`),

  // Payments
  getPayments: (page = 1, limit = 10) =>
    api.get(`/payments?page=${page}&limit=${limit}`),
  
  getPayment: (id: string) => api.get(`/payments/${id}`),
  
  refundPayment: (id: string) => api.post(`/payments/${id}/refund`),
};

export default api;
