import axios from 'axios';

const normalizeApiBaseUrl = (url?: string) => {
  const fallback = 'http://localhost:3001';
  const rawUrl = (url && url.trim().length > 0 ? url : fallback).trim();
  const trimmed = rawUrl.replace(/\/+$/, '');

  if (/\/api\/v\d+$/i.test(trimmed)) {
    return trimmed;
  }

  if (/\/api$/i.test(trimmed)) {
    return `${trimmed}/v1`;
  }

  return `${trimmed}/api/v1`;
};

const API_BASE_URL = normalizeApiBaseUrl(process.env.NEXT_PUBLIC_API_URL);

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para eliminar Content-Type cuando se envía FormData
api.interceptors.request.use((config) => {
  if (config.data instanceof FormData) {
    // Eliminar Content-Type para que el navegador establezca el boundary correcto
    delete config.headers['Content-Type'];
  }
  return config;
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
      // Token expirado o inválido; limpiar el token local y dejar que la vista maneje el error
      if (typeof window !== 'undefined') {
        localStorage.removeItem('access_token');
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
  
  createUser: (data: any) => api.post('/auth/register', data),
  
  updateUser: (id: string, data: any) => api.patch(`/users/${id}`, data),
  
  deleteUser: (id: string) => api.delete(`/users/${id}`),
  
  activateUser: (id: string) => api.post(`/users/${id}/activate`),
  
  deactivateUser: (id: string) => api.post(`/users/${id}/deactivate`),
  
  verifyUser: (id: string) => api.post(`/users/${id}/verify`),

  // Artists
  getArtists: (page = 1, limit = 100) =>
    api.get(`/artists?page=${page}&limit=${limit}`),
  
  getArtist: (id: string) => api.get(`/artists/${id}`),
  
  getArtistStats: (id: string) => api.get(`/artists/${id}/stats`),
  
  verifyArtist: (id: string) => api.patch(`/artists/${id}/verify`),

  // Songs
  getSongs: (page = 1, limit = 10, all = true) =>
    api.get(`/songs?page=${page}&limit=${limit}&all=${all}`),
  
  getSong: (id: string) => api.get(`/songs/${id}`),
  
  getTopSongsByPlays: (limit = 10) => api.get(`/songs/top?limit=${limit}`),
  
  uploadSong: (
    audioFile: File, 
    coverFile: File | undefined, 
    songData: {
      title: string;
      artistId: string;
      albumId?: string;
      genreId?: string;
      status?: string;
      duration?: number;
    },
    onUploadProgress?: (progressEvent: { loaded: number; total: number }) => void
  ) => {
    const formData = new FormData();
    formData.append('audio', audioFile);
    if (coverFile) {
      formData.append('cover', coverFile);
    }
    formData.append('title', songData.title);
    formData.append('artistId', songData.artistId);
    if (songData.albumId) {
      formData.append('albumId', songData.albumId);
    }
    if (songData.genreId) {
      formData.append('genreId', songData.genreId);
    }
    if (songData.status) {
      formData.append('status', songData.status);
    }
    if (songData.duration !== undefined) {
      formData.append('duration', songData.duration.toString());
    }
    return api.post('/songs/upload', formData, {
      onUploadProgress: (progressEvent) => {
        if (progressEvent.total && onUploadProgress) {
          onUploadProgress({
            loaded: progressEvent.loaded,
            total: progressEvent.total,
          });
        }
      },
    });
  },
  
  createSong: (data: any) => api.post('/songs', data),
  
  updateSong: (id: string, data: any) => api.patch(`/songs/${id}`, data),
  
  deleteSong: (id: string) => api.delete(`/songs/${id}`),

  // Playlists
  getPlaylists: (page = 1, limit = 10) =>
    api.get(`/playlists?page=${page}&limit=${limit}`),
  
  getPlaylist: (id: string) => api.get(`/playlists/${id}`),
  
  getFeaturedPlaylists: (limit = 10) => api.get(`/playlists/featured?limit=${limit}`),
  
  createPlaylist: (data: any) => api.post('/playlists', data),
  
  updatePlaylist: (id: string, data: any) => api.put(`/playlists/${id}`, data),
  
  deletePlaylist: (id: string) => api.delete(`/playlists/${id}`),
  
  toggleFeaturedPlaylist: (id: string) => api.patch(`/playlists/${id}/feature`),
  
  uploadPlaylistCover: (id: string, coverFile: File) => {
    const formData = new FormData();
    formData.append('cover', coverFile);
    return api.post(`/playlists/${id}/cover`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  },
  
  addSongToPlaylist: (playlistId: string, songId: string) =>
    api.post(`/playlists/${playlistId}/songs/${songId}`),
  
  removeSongFromPlaylist: (playlistId: string, songId: string) =>
    api.delete(`/playlists/${playlistId}/songs/${songId}`),

  // Analytics
  getGlobalStats: () => api.get('/analytics/global'),
  
  getTopArtists: (limit = 10) => api.get(`/analytics/top-artists?limit=${limit}`),
  
  getTopSongs: (limit = 10) => api.get(`/analytics/top-songs?limit=${limit}`),

  // Payments
  getPayments: (page = 1, limit = 10) =>
    api.get(`/payments?page=${page}&limit=${limit}`),
  
  getPayment: (id: string) => api.get(`/payments/${id}`),
  
  refundPayment: (id: string) => api.post(`/payments/${id}/refund`),

  // Featured Content
  getFeaturedSongs: (limit = 10) => api.get(`/featured/songs?limit=${limit}`),
  featureSong: (id: string) => api.post(`/featured/songs/${id}/feature`),
  unfeatureSong: (id: string) => api.delete(`/featured/songs/${id}/feature`),

  getFeaturedArtists: (limit = 10) => api.get(`/featured/artists?limit=${limit}`),
  featureArtist: (id: string) => api.post(`/featured/artists/${id}/feature`),
  unfeatureArtist: (id: string) => api.delete(`/featured/artists/${id}/feature`),

  getFeaturedPlaylists: (limit = 10) => api.get(`/featured/playlists?limit=${limit}`),
  featurePlaylist: (id: string) => api.post(`/featured/playlists/${id}/feature`),
  unfeaturePlaylist: (id: string) => api.delete(`/featured/playlists/${id}/feature`),
};

export default api;
