'use client';

import { useState, useEffect } from 'react';
import { signIn, useSession } from 'next-auth/react';
import { useRouter, useSearchParams } from 'next/navigation';
import { toast } from 'react-hot-toast';
import { MusicalNoteIcon, EyeIcon, EyeSlashIcon, ShieldCheckIcon } from '@heroicons/react/24/outline';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const router = useRouter();
  const searchParams = useSearchParams();
  const { data: session, status } = useSession();

  useEffect(() => {
    // Si ya hay sesión, redirigir al dashboard
    if (status === 'authenticated' && session) {
      router.push('/dashboard');
      return;
    }

    // Mostrar error si viene de la ruta de error de NextAuth
    const error = searchParams.get('error');
    if (error === 'Configuration') {
      toast.error('Error de configuración. Verifica NEXTAUTH_SECRET y NEXTAUTH_URL');
      console.error('Error de configuración de NextAuth. Verifica las variables de entorno.');
    }
  }, [session, status, router, searchParams]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      // Usar NextAuth para todas las credenciales (incluyendo las de desarrollo)
      const result = await signIn('credentials', {
        email,
        password,
        redirect: false,
        callbackUrl: '/dashboard',
      });

      if (result?.error) {
        if (result.error === 'Configuration') {
          toast.error('Error de configuración. Verifica las variables de entorno.');
          console.error('Error de configuración de NextAuth. Verifica NEXTAUTH_SECRET y NEXTAUTH_URL');
        } else if (result.error === 'CredentialsSignin') {
          toast.error('Credenciales inválidas');
        } else {
          toast.error(`Error: ${result.error}`);
        }
        setIsLoading(false);
        return;
      }

      console.log('[Login] Resultado de signIn:', result);
      
      if (result?.ok || result?.url) {
        toast.success('Inicio de sesión exitoso');
        console.log('[Login] Login exitoso, esperando sesión...');
        
        // Esperar a que NextAuth establezca la sesión antes de redirigir
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Verificar que la sesión esté lista antes de redirigir
        try {
          const sessionResponse = await fetch('/api/auth/session');
          const sessionData = await sessionResponse.json();
          console.log('[Login] Sesión verificada:', sessionData);
          
          if (sessionData && sessionData.user) {
            console.log('[Login] Sesión válida, redirigiendo al dashboard');
            // Usar window.location para una redirección completa que force la recarga de la sesión
            window.location.href = '/dashboard';
          } else {
            console.error('[Login] Sesión no válida después del login');
            toast.error('Error: No se pudo establecer la sesión');
            setIsLoading(false);
          }
        } catch (sessionError) {
          console.error('[Login] Error al verificar sesión:', sessionError);
          // Intentar redirigir de todas formas
          window.location.href = '/dashboard';
        }
      } else {
        console.error('[Login] Error en login:', result);
        toast.error('Error al iniciar sesión');
        setIsLoading(false);
      }
    } catch (error) {
      console.error('Error en login:', error);
      toast.error('Error al iniciar sesión');
      setIsLoading(false);
    }
  };

  return (
    <div className="login-container">
      <style jsx>{`
        .login-container {
          min-height: 100vh;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          display: flex;
          align-items: center;
          justify-content: center;
          position: relative;
          overflow: hidden;
        }
        
        .login-container::before {
          content: '';
          position: absolute;
          top: -50%;
          left: -50%;
          width: 200%;
          height: 200%;
          background: radial-gradient(circle, rgba(255,255,255,0.1) 0%, transparent 70%);
          animation: float 20s ease-in-out infinite;
        }
        
        @keyframes float {
          0%, 100% { transform: translate(0, 0) rotate(0deg); }
          33% { transform: translate(30px, -30px) rotate(120deg); }
          66% { transform: translate(-20px, 20px) rotate(240deg); }
        }
        
        .login-card {
          background: rgba(255, 255, 255, 0.95);
          backdrop-filter: blur(20px);
          border-radius: 24px;
          padding: 48px;
          width: 100%;
          max-width: 448px;
          box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
          border: 1px solid rgba(255, 255, 255, 0.2);
          position: relative;
          z-index: 10;
        }
        
        .logo-container {
          text-align: center;
          margin-bottom: 32px;
        }
        
        .logo {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          width: 80px;
          height: 80px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          border-radius: 20px;
          box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
          margin-bottom: 24px;
          transition: transform 0.3s ease;
        }
        
        .logo:hover {
          transform: translateY(-2px);
        }
        
        .title {
          font-size: 32px;
          font-weight: 800;
          color: #1f2937;
          margin-bottom: 8px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }
        
        .subtitle {
          color: #6b7280;
          font-size: 16px;
          font-weight: 500;
        }
        
        .form-group {
          margin-bottom: 24px;
        }
        
        .form-label {
          display: block;
          font-size: 14px;
          font-weight: 600;
          color: #374151;
          margin-bottom: 8px;
        }
        
        .form-input {
          width: 100%;
          padding: 16px;
          border: 2px solid #e5e7eb;
          border-radius: 12px;
          font-size: 16px;
          transition: all 0.3s ease;
          background: #f9fafb;
        }
        
        .form-input:focus {
          outline: none;
          border-color: #667eea;
          background: white;
          box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }
        
        .password-container {
          position: relative;
        }
        
        .password-toggle {
          position: absolute;
          right: 16px;
          top: 50%;
          transform: translateY(-50%);
          background: none;
          border: none;
          color: #9ca3af;
          cursor: pointer;
          padding: 4px;
        }
        
        .submit-button {
          width: 100%;
          padding: 16px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          border: none;
          border-radius: 12px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s ease;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 12px;
          box-shadow: 0 10px 25px rgba(102, 126, 234, 0.4);
        }
        
        .submit-button:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 15px 35px rgba(102, 126, 234, 0.5);
        }
        
        .submit-button:disabled {
          opacity: 0.7;
          cursor: not-allowed;
          transform: none;
        }
        
        .spinner {
          width: 20px;
          height: 20px;
          border: 2px solid rgba(255, 255, 255, 0.3);
          border-top: 2px solid white;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        
        .footer {
          text-align: center;
          margin-top: 24px;
          color: #9ca3af;
          font-size: 14px;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
        }
        
        .status-dot {
          width: 8px;
          height: 8px;
          background: #10b981;
          border-radius: 50%;
          animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
      `}</style>
      
      <div className="login-card">
        <div className="logo-container">
          <div className="logo">
            <MusicalNoteIcon className="w-10 h-10 text-white" />
          </div>
          <h1 className="title">Vintage Music</h1>
          <p className="subtitle">Panel de Administración</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="email" className="form-label">
              Correo electrónico
            </label>
            <input
              id="email"
              name="email"
              type="email"
              autoComplete="email"
              required
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="form-input"
              placeholder="admin@vintagemusic.com"
            />
          </div>

          <div className="form-group">
            <label htmlFor="password" className="form-label">
              Contraseña
            </label>
            <div className="password-container">
              <input
                id="password"
                name="password"
                type={showPassword ? 'text' : 'password'}
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="form-input"
                placeholder="••••••••"
              />
              <button
                type="button"
                className="password-toggle"
                onClick={() => setShowPassword(!showPassword)}
              >
                {showPassword ? (
                  <EyeSlashIcon className="w-5 h-5" />
                ) : (
                  <EyeIcon className="w-5 h-5" />
                )}
              </button>
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="submit-button"
          >
            {isLoading ? (
              <div className="spinner" />
            ) : (
              <ShieldCheckIcon className="w-5 h-5" />
            )}
            {isLoading ? 'Iniciando sesión...' : 'Acceder al Panel'}
          </button>
        </form>

        <div className="footer">
          <div className="status-dot"></div>
          <span>Solo administradores autorizados</span>
        </div>
      </div>
    </div>
  );
}