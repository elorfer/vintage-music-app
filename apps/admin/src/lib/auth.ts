import { NextAuthOptions } from 'next-auth';
import CredentialsProvider from 'next-auth/providers/credentials';
import { api } from './api';
import { config } from '@/config/env';
import { logger } from './logger';
import { AppErrors, ErrorHandler } from './error-handler';

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          logger.warn('Intento de login sin credenciales completas', 'AUTH');
          return null;
        }

        try {
          logger.info(`Intento de login para ${credentials.email}`, 'AUTH');

          // Credenciales de desarrollo
          if (credentials.email === 'admin@vintagemusic.com' && credentials.password === 'admin123') {
            logger.info('Login exitoso con credenciales de desarrollo', 'AUTH', { email: credentials.email });
            return {
              id: 'dev-admin-001',
              email: credentials.email,
              name: 'Admin Vintage',
              role: 'admin',
              accessToken: 'dev-token-123',
            };
          }

          // Autenticación real con backend
          const response = await api.post('/auth/login', {
            email: credentials.email,
            password: credentials.password,
          });

          const { access_token, user } = response.data;

          if (user.role !== 'admin') {
            logger.warn('Intento de login de usuario no admin', 'AUTH', { email: credentials.email, role: user.role });
            throw AppErrors.FORBIDDEN('Acceso denegado. Solo administradores pueden acceder.');
          }

          logger.info('Login exitoso', 'AUTH', { email: credentials.email, userId: user.id });

          return {
            id: user.id,
            email: user.email,
            name: `${user.firstName} ${user.lastName}`,
            role: user.role,
            accessToken: access_token,
          };
        } catch (error) {
          const appError = ErrorHandler.handle(error as Error, 'AUTH');
          logger.error('Error en autenticación', 'AUTH', { 
            email: credentials.email, 
            error: appError.message,
            code: appError.code 
          });
          return null;
        }
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.accessToken = (user as any).accessToken;
        token.role = (user as any).role;
      }
      return token;
    },
    async session({ session, token }) {
      if (token) {
        session.accessToken = token.accessToken as string;
        session.user.role = token.role as string;
      }
      return session;
    },
  },
  pages: {
    signIn: '/login',
  },
  session: {
    strategy: 'jwt',
  },
  secret: config.nextAuth.secret,
};


