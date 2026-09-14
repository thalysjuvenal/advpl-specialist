import Link from 'next/link';
import { HomeLayout } from 'fumadocs-ui/layouts/home';
import { baseOptions } from '@/lib/layout.shared';

// IMPORTANT: manter esta versao em sync com .claude-plugin/plugin.json .
// validate-plugin.yml falha se este valor divergir de plugin.json.
const PLUGIN_VERSION = 'v1.5.1';

export default function Home() {
  return (
    <HomeLayout {...baseOptions()}>
      {/* Hero */}
      <section className="flex flex-col items-center text-center px-4 py-20 md:py-32 gap-6 max-w-4xl mx-auto">
        <div className="flex gap-2 flex-wrap justify-center">
          <span className="inline-flex items-center rounded-full border px-3 py-1 text-xs font-medium text-fd-muted-foreground">
            {PLUGIN_VERSION}
          </span>
          <span className="inline-flex items-center rounded-full border px-3 py-1 text-xs font-medium text-fd-muted-foreground">
            MIT License
          </span>
          <span className="inline-flex items-center rounded-full border px-3 py-1 text-xs font-medium text-fd-muted-foreground">
            Claude Code
          </span>
          <span className="inline-flex items-center rounded-full border px-3 py-1 text-xs font-medium text-fd-muted-foreground">
            TOTVS Protheus
          </span>
        </div>

        <h1 className="text-4xl font-bold tracking-tight md:text-5xl lg:text-6xl">
          advpl-specialist
        </h1>

        <p className="text-lg text-fd-muted-foreground max-w-2xl md:text-xl">
          Plugin para Claude Code especializado em <strong className="text-fd-foreground">ADVPL</strong> e{' '}
          <strong className="text-fd-foreground">TLPP</strong> para desenvolvimento no ecossistema{' '}
          <strong className="text-fd-foreground">TOTVS Protheus</strong>
        </p>

        <div className="flex gap-3 mt-2">
          <Link
            href="/docs"
            className="inline-flex items-center justify-center rounded-lg bg-fd-primary text-fd-primary-foreground px-6 py-2.5 text-sm font-medium transition-colors hover:opacity-90"
          >
            Comecar
          </Link>
          <a
            href="https://github.com/thalysjuvenal/advpl-specialist"
            target="_blank"
            rel="noreferrer noopener"
            className="inline-flex items-center justify-center rounded-lg border bg-fd-background px-6 py-2.5 text-sm font-medium transition-colors hover:bg-fd-accent hover:text-fd-accent-foreground"
          >
            GitHub
          </a>
        </div>
      </section>

      {/* Cards */}
      {/* IMPORTANT: manter estes numeros em sync com o repo —
          Comandos = arquivos .md em commands/ | Agentes = arquivos .md em agents/ | Skills = diretorios em skills/ */}
      <section className="grid grid-cols-1 md:grid-cols-3 gap-6 max-w-4xl mx-auto px-4 pb-12">
        <div className="flex flex-col items-center text-center rounded-xl border bg-fd-card p-6 gap-2">
          <span className="text-3xl font-bold">15</span>
          <span className="text-sm font-medium">Comandos</span>
          <span className="text-xs text-fd-muted-foreground">
            Invocaveis diretamente no Claude Code
          </span>
        </div>
        <div className="flex flex-col items-center text-center rounded-xl border bg-fd-card p-6 gap-2">
          <span className="text-3xl font-bold">10</span>
          <span className="text-sm font-medium">Agentes</span>
          <span className="text-xs text-fd-muted-foreground">
            Especializados em tarefas especificas
          </span>
        </div>
        <div className="flex flex-col items-center text-center rounded-xl border bg-fd-card p-6 gap-2">
          <span className="text-3xl font-bold">19</span>
          <span className="text-sm font-medium">Skills</span>
          <span className="text-xs text-fd-muted-foreground">
            Bases de conhecimento e referencia
          </span>
        </div>
      </section>

      {/* Para quem */}
      <section className="max-w-4xl mx-auto px-4 pb-12">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="rounded-xl border bg-fd-card p-6">
            <h3 className="text-lg font-semibold mb-3">Para Desenvolvedores</h3>
            <ul className="text-sm text-fd-muted-foreground space-y-2">
              <li>Geracao de codigo ADVPL/TLPP com boas praticas</li>
              <li>Migracao de ADVPL procedural para TLPP OOP</li>
              <li>Diagnostico de erros e revisao de codigo</li>
              <li>Testes unitarios ProBat e referencia embutida</li>
              <li>Refatoracao e documentacao automatica</li>
            </ul>
          </div>
          <div className="rounded-xl border bg-fd-card p-6">
            <h3 className="text-lg font-semibold mb-3">Para Consultores Funcionais</h3>
            <ul className="text-sm text-fd-muted-foreground space-y-2">
              <li>Explicacao de codigo em linguagem simples</li>
              <li>Scripts de dicionario SX via linguagem natural</li>
              <li>Consulta de processos e integracoes ERP</li>
              <li>Changelog formatado para entregar ao cliente</li>
            </ul>
          </div>
        </div>
      </section>

      {/* Quick Install */}
      <section className="max-w-4xl mx-auto px-4 pb-20">
        <div className="rounded-xl border bg-fd-card p-6 text-center">
          <h3 className="text-lg font-semibold mb-3">Instalacao rapida</h3>
          <div className="bg-fd-background rounded-lg border p-4 text-left font-mono text-sm overflow-x-auto">
            <div className="text-fd-muted-foreground"># Dentro do Claude Code</div>
            <div>/plugin marketplace add thalysjuvenal/advpl-specialist</div>
            <div>/plugin install advpl-specialist@thalysjuvenal-advpl-specialist</div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t py-8 text-center text-sm text-fd-muted-foreground space-y-3">
        <p>
          Criado por{' '}
          <a
            href="https://github.com/thalysjuvenal"
            target="_blank"
            rel="noreferrer noopener"
            className="font-medium text-fd-foreground hover:underline"
          >
            Thalys Augusto
          </a>
          {' '}|{' '}
          <a
            href="https://www.linkedin.com/in/thalysjuvenal"
            target="_blank"
            rel="noreferrer noopener"
            className="font-medium text-fd-foreground hover:underline"
          >
            LinkedIn
          </a>
        </p>
        <p className="text-xs max-w-2xl mx-auto">
          Protheus, ADVPL, TLPP e TOTVS sao produtos e marcas registradas de propriedade da TOTVS S.A.
          Este plugin e um projeto independente e nao possui vinculo com a TOTVS, suas franquias ou representantes.
        </p>
      </footer>
    </HomeLayout>
  );
}
