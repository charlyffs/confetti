import '../styles/tailwind.css'
import type { AppProps } from 'next/app'
import CssBaseline from '@mui/material/CssBaseline'
import {StyledEngineProvider} from '@mui/material/styles'

function MyApp({ Component, pageProps }: AppProps) {
  return (
    <StyledEngineProvider injectFirst>
      <CssBaseline />
      <div className="absolute inset-0 bg-slate-900">

      <Component {...pageProps} />
      </div>
    </StyledEngineProvider>
  );
}

export default MyApp;
