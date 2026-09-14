import { RootProvider } from 'fumadocs-ui/provider/next';
import type { Metadata } from 'next';
import type { ReactNode } from 'react';
import Script from 'next/script';
import CustomSearchDialog from '@/components/search-dialog';
import './global.css';

export const metadata: Metadata = {
  title: {
    default: 'advpl-specialist',
    template: '%s | advpl-specialist',
  },
  description:
    'Plugin para Claude Code especializado em ADVPL e TLPP para desenvolvimento no ecossistema TOTVS Protheus',
  icons: {
    icon: '/advpl-specialist/favicon.svg',
  },
  openGraph: {
    title: 'advpl-specialist',
    description:
      'Plugin para Claude Code especializado em ADVPL e TLPP para desenvolvimento no ecossistema TOTVS Protheus. 15 comandos, 10 agentes, 19 skills.',
    url: 'https://thalysjuvenal.github.io/advpl-specialist',
    siteName: 'advpl-specialist',
    type: 'website',
    locale: 'pt_BR',
    images: [
      {
        url: 'https://thalysjuvenal.github.io/advpl-specialist/og-image.png',
        width: 1200,
        height: 630,
        alt: 'advpl-specialist - Plugin para Claude Code especializado em ADVPL e TLPP para TOTVS Protheus',
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'advpl-specialist',
    description:
      'Plugin para Claude Code especializado em ADVPL e TLPP para TOTVS Protheus',
    images: ['https://thalysjuvenal.github.io/advpl-specialist/og-image.png'],
  },
};

export default function Layout({ children }: { children: ReactNode }) {
  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <head>
        <Script
          src="https://www.googletagmanager.com/gtag/js?id=G-KMBZRYWHNM"
          strategy="afterInteractive"
        />
        <Script id="google-analytics" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', 'G-KMBZRYWHNM');
          `}
        </Script>
      </head>
      <body className="flex flex-col min-h-screen">
        <RootProvider
          theme={{
            defaultTheme: 'dark',
          }}
          search={{
            SearchDialog: CustomSearchDialog,
          }}
          i18n={{
            locale: 'pt-BR',
            translations: {
              search: 'Pesquisar',
              searchNoResult: 'Nenhum resultado encontrado',
              toc: 'Nesta pagina',
              tocNoHeadings: 'Sem topicos',
              lastUpdate: 'Ultima atualizacao',
              chooseLanguage: 'Escolher idioma',
              nextPage: 'Proxima',
              previousPage: 'Anterior',
              chooseTheme: 'Alternar tema',
              editOnGithub: 'Editar no GitHub',
            },
          }}
        >
          {children}
        </RootProvider>
      </body>
    </html>
  );
}
