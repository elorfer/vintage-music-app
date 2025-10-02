import { withAuth } from 'next-auth/middleware';

export default withAuth(
  function middleware(req) {
    // Aquí puedes agregar lógica adicional si es necesario
  },
  {
    callbacks: {
      authorized: ({ token, req }) => {
        // Permitir acceso a la página de login sin token
        if (req.nextUrl.pathname === '/login') {
          return true;
        }
        
        // Requerir token para todas las demás rutas
        return !!token;
      },
    },
  }
);

export const config = {
  matcher: ['/dashboard/:path*', '/api/:path*'],
};


