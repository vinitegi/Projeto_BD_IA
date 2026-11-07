# SmartCampus RAG

Assistente acadêmico inteligente que responde perguntas sobre os **documentos de uma disciplina** (RAG com **ChromaDB**) e consulta os **dados do aluno** em um **banco relacional PostgreSQL** (procedures, functions e triggers), usando **Function Calling** com o **Gemini**.

Trabalho em grupo da disciplina de Banco de Dados.

**Autores:** Vinícius Coretti Tegi e Filippi Afonso Ferreira Leite

> Exemplo: *"Qual é o conteúdo da prova e qual é minha média atual?"*
> O chatbot busca o conteúdo nos documentos (RAG) **e** chama a procedure que calcula a média no PostgreSQL, juntando tudo em uma única resposta.

---

## Como funciona

```
                     ┌─────────────────────────────────┐
   Aluno ──────────► │   Chatbot (Gemini + ferramentas) │
                     └──────┬───────────────────┬──────┘
                            │                   │
                 buscar_documentos       consultar_media
                            │            consultar_boletim
                            │            listar_alertas
                            │            abrir_chamado
                            ▼                   ▼
                    ┌───────────────┐   ┌──────────────────────────┐
                    │   ChromaDB    │   │   PostgreSQL             │
                    │  (embeddings  │   │   tabelas + functions +  │
                    │  dos PDFs)    │   │   procedures + triggers  │
                    └───────────────┘   └──────────────────────────┘
```

1. `python main.py indexar` lê os arquivos da pasta `docs/`, divide em trechos (chunks), gera embeddings com o Gemini e grava no ChromaDB.
2. Na conversa, o Gemini recebe a pergunta e **decide sozinho** quais ferramentas chamar (Function Calling).
3. `buscar_documentos` faz a busca por similaridade no ChromaDB. As outras ferramentas executam procedures e consultas no PostgreSQL.
4. O Gemini escreve a resposta final com base nos resultados, citando o documento de origem quando usa o RAG.

**Segurança:** as ferramentas são criadas já vinculadas ao aluno que fez login. O modelo não escolhe o `aluno_id`, então não consegue consultar dados de outra pessoa. Todas as consultas SQL são parametrizadas (nada de texto concatenado), e a senha do banco e a chave da API ficam em variáveis de ambiente, fora do código.

## Tecnologias

| Camada | Tecnologia |
|---|---|
| Linguagem | Python 3.10 ou superior |
| Banco relacional | PostgreSQL 14 ou superior (PL/pgSQL) |
| Banco vetorial | ChromaDB (persistente, similaridade por cosseno) |
| LLM e embeddings | Google Gemini (`google-genai`), modelo de embeddings `gemini-embedding-001` |
| Driver do banco | `psycopg` 3 |
| Leitura de PDF | `pypdf` |

## Estrutura do projeto

```
.
├── sql/                       # scripts do banco (ordem de execução abaixo)
├── docs/                      # documentos usados na base vetorial (PDFs)
├── main.py                    # indexação: lê docs/, gera chunks e embeddings, grava no ChromaDB
├── chatbot.py                 # chatbot RAG com Function Calling integrado ao PostgreSQL
└── README.md
```

Documentos usados na base vetorial (pasta `docs/`):

- `atividade_sql.pdf`
- `aula-pratica-plsql-procedures.pdf`
- `aula-pratica-triggers-oracle-freesql.pdf`
- `Aula_2_Revisao_de_Banco_de_Dados.pdf`
- `Projeto de Banco de Dados.pdf`

## Pré-requisitos

- Python 3.10 ou superior
- PostgreSQL 14 ou superior (as procedures usam parâmetros `OUT`, que exigem a versão 14+)
- Chave de API do Gemini (gratuita): https://aistudio.google.com/apikey

## Passo a passo para executar

### 1. Baixar o projeto e instalar as dependências

```bash
git clone <URL_DO_REPOSITORIO>
cd <PASTA_DO_PROJETO>

python -m venv .venv
.venv\Scripts\activate            # Windows (PowerShell)
# source .venv/bin/activate       # Linux / Mac

pip install chromadb google-genai pypdf "psycopg[binary]"
```

### 2. Criar o banco de dados

Crie o banco `smartcampus` (no pgAdmin: botão direito em *Databases* → *Create* → *Database*; ou, no `psql`: `CREATE DATABASE smartcampus;`). Conecte nele e execute os scripts da pasta `sql/` **nesta ordem**:

| Ordem | Conteúdo |
|---|---|
| 1 | Tabelas: `alunos`, `disciplinas`, `matriculas`, `notas`, `chamados` |
| 2 | Tabelas de apoio: `log_alteracao_notas` e `alertas` |
| 3 | Inserts de exemplo |
| 4 | Functions: `fn_media_matricula`, `fn_situacao`, `fn_verificar_alerta_media` |
| 5 | Procedures: `sp_calcular_media`, `sp_abrir_chamado` e a function `sp_gerar_boletim` |
| 6 | Triggers: auditoria de notas e alerta de média baixa |
| 7 | Alertas dos dados iniciais (comando abaixo) |

Como os triggers só disparam para notas inseridas **depois** deles, gere os alertas dos dados de exemplo com:

```sql
SELECT fn_verificar_alerta_media(id) FROM matriculas;
```

**Conferência:** deve retornar 19 notas, 16 matrículas e 6 alertas ativos.

```sql
SELECT (SELECT count(*) FROM notas)                AS notas,
       (SELECT count(*) FROM matriculas)           AS matriculas,
       (SELECT count(*) FROM alertas WHERE ativo)  AS alertas_ativos;
```

### 3. Definir as variáveis de ambiente

A chave do Gemini e a senha do banco **não ficam no código**. Defina no mesmo terminal em que vai rodar o projeto:

```powershell
# Windows (PowerShell)
$env:GEMINI_API_KEY="sua_chave_do_gemini"
$env:DB_PASSWORD="senha_do_postgres"
```

```bash
# Linux / Mac
export GEMINI_API_KEY="sua_chave_do_gemini"
export DB_PASSWORD="senha_do_postgres"
```

Se o seu PostgreSQL usa outro usuário, host, porta ou nome de banco, defina também `DB_USER`, `DB_HOST`, `DB_PORT` e `DB_NAME`. Os valores padrão são `postgres`, `localhost`, `5432` e `smartcampus`.

### 4. Criar a base vetorial (ChromaDB)

```bash
python main.py indexar
```

Lê todos os `.pdf`, `.md` e `.txt` da pasta `docs/`, divide em trechos de cerca de 800 caracteres (com 150 de sobreposição), gera os embeddings e grava na pasta `chroma_db/`. Para testar só a busca:

```bash
python main.py buscar "o que é uma trigger?"
```

Se você alterar os documentos de `docs/`, rode o `indexar` de novo.

### 5. Rodar o chatbot

```bash
python chatbot.py 20260002
```

O número é a **matrícula do aluno**. Sem ele, o programa pergunta ao iniciar. Digite `sair` para encerrar. As linhas `[ferramenta] ...` mostram quais funções o Gemini decidiu chamar.

## Alunos de exemplo

| Matrícula | Aluno | Situação para demonstração |
|---|---|---|
| 20260001 | Ana Beatriz Souza | Médias boas em todas as disciplinas |
| 20260002 | Bruno Henrique Lima | Média baixa em Banco de Dados e IA (alertas) |
| 20260004 | Diego Ferreira | Reprovado por faltas em Banco de Dados (11 faltas, limite de 10) |
| 20260006 | Felipe Araújo | Média baixa em BD e Engenharia de Software |

## Perguntas para testar

| Pergunta | O que o sistema faz |
|---|---|
| "O que é uma trigger?" | RAG: busca no PDF de triggers |
| "Qual minha média em Banco de Dados?" | PostgreSQL: procedure `sp_calcular_media` |
| "Me mostra meu boletim" | PostgreSQL: function `sp_gerar_boletim` |
| "Tenho algum alerta?" | PostgreSQL: tabela `alertas`, preenchida por trigger |
| "Abre um chamado pedindo revisão da P1 de Banco de Dados" | PostgreSQL: procedure `sp_abrir_chamado` |
| **"Qual é o conteúdo da prova e qual é minha média atual?"** | **RAG + PostgreSQL na mesma resposta** |
| "Qual a capital da França?" | Responde que não encontrou nos documentos (não inventa) |

## Banco de dados

### Tabelas

| Tabela | Descrição |
|---|---|
| `alunos` | Dados do aluno (matrícula, nome, curso) |
| `disciplinas` | Disciplinas, professor, carga horária e total de aulas |
| `matriculas` | Aluno cursando uma disciplina em um semestre, com as faltas |
| `notas` | Avaliações de cada matrícula, com valor e peso |
| `chamados` | Dúvidas e pedidos abertos pelos alunos |
| `log_alteracao_notas` | Auditoria de alterações de nota (preenchida por trigger) |
| `alertas` | Alertas de média baixa (preenchida por trigger) |

### Functions

| Function | Função |
|---|---|
| `fn_media_matricula(matricula_id)` | Média ponderada das notas de uma matrícula |
| `fn_situacao(media, faltas, total_aulas)` | `REGULAR`, `EM RISCO`, `REPROVADO POR FALTAS` ou `SEM NOTAS` |
| `fn_verificar_alerta_media(matricula_id)` | Cria, atualiza ou encerra o alerta de média abaixo de 6,0 |

### Procedures

| Objeto | Função |
|---|---|
| `sp_calcular_media(matricula_id, OUT media, OUT situacao)` | Calcula a média e a situação de uma matrícula |
| `sp_abrir_chamado(aluno, disciplina, assunto, descricao, OUT id)` | Abre um chamado e devolve o id |
| `sp_gerar_boletim(aluno_id, semestre)` | Boletim do aluno (no PostgreSQL é uma function, pois só function devolve tabela) |

### Triggers

| Trigger | Evento | Efeito |
|---|---|---|
| `trg_notas_auditoria` | `AFTER UPDATE OR DELETE` em `notas` | Grava valor antigo e novo, usuário e data em `log_alteracao_notas` |
| `trg_notas_alerta` | `AFTER INSERT OR UPDATE` em `notas` | Cria o alerta se a média ficar abaixo de 6,0 e o encerra quando ela se recupera |

### Testando as procedures e os triggers direto no banco

```sql
CALL sp_calcular_media(4, NULL, NULL);               -- média 4.50, EM RISCO
SELECT * FROM sp_gerar_boletim(2, '2026.2');         -- boletim do Bruno
SELECT * FROM alertas WHERE ativo;                   -- alertas gerados por trigger

-- altera uma nota: dispara a auditoria e encerra o alerta do Bruno em BD
UPDATE notas SET valor = 7.00 WHERE matricula_id = 4 AND avaliacao = 'P1';
SELECT * FROM log_alteracao_notas;
SELECT * FROM alertas WHERE matricula_id = 4;        -- ativo = false
```

## Base vetorial (ChromaDB)

- Coleção `smartcampus_docs`, salva na pasta `chroma_db/`, com similaridade de cosseno.
- Chunking: trechos de até 800 caracteres com 150 de sobreposição, cortando preferencialmente no fim de parágrafos.
- Embeddings: `gemini-embedding-001`, com `RETRIEVAL_DOCUMENT` para os trechos e `RETRIEVAL_QUERY` para a pergunta.
- Cada trecho guarda como metadado o arquivo de origem, usado para citar a fonte na resposta.

## Divisão de tarefas

| Integrante | Responsabilidades |
|---|---|
| **Vinícius Coretti Tegi** | Banco relacional PostgreSQL (tabelas, inserts, functions, procedures e triggers) e integração do chatbot com o banco via Function Calling |
| **Filippi Afonso Ferreira Leite** | Base vetorial no ChromaDB (documentos, chunking e embeddings) e chatbot RAG com o Gemini |
| **Ambos** | README, vídeo de demonstração e apresentação |

## Problemas comuns

| Erro | Solução |
|---|---|
| `Defina a variavel de ambiente GEMINI_API_KEY` | Defina a variável no mesmo terminal em que vai rodar (passo 3) |
| `Nao consegui conectar ao PostgreSQL` ou `password authentication failed` | Confira se o PostgreSQL está rodando e se `DB_PASSWORD` (e `DB_USER`) estão corretos |
| `procedure sp_calcular_media does not exist` | Os scripts SQL não foram executados **neste** banco (passo 2) |
| `Nenhuma colecao em chroma_db/` | Rode `python main.py indexar` (passo 4) |
| `503 UNAVAILABLE` | O Gemini está sobrecarregado. O código já tenta de novo sozinho; se persistir, espere alguns minutos ou troque `MODELO_CHAT` em `chatbot.py` |
| `429 RESOURCE_EXHAUSTED` | Limite do plano gratuito. Espere cerca de um minuto |
| Erro de modelo não encontrado | Troque `MODELO_CHAT` em `chatbot.py` por um modelo disponível na sua conta |
