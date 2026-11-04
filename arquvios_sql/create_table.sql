CREATE TABLE alunos (
    id             SERIAL PRIMARY KEY,
    matricula      VARCHAR(12)  NOT NULL UNIQUE,
    nome           VARCHAR(100) NOT NULL,
    email          VARCHAR(120) NOT NULL UNIQUE,
    curso          VARCHAR(80)  NOT NULL,
    data_ingresso  DATE         NOT NULL
);

CREATE TABLE disciplinas (
    id             SERIAL PRIMARY KEY,
    codigo         VARCHAR(10)  NOT NULL UNIQUE,
    nome           VARCHAR(100) NOT NULL,
    professor      VARCHAR(100) NOT NULL,
    carga_horaria  INT          NOT NULL,
    total_aulas    INT          NOT NULL
);

CREATE TABLE matriculas (
    id             SERIAL PRIMARY KEY,
    aluno_id       INT         NOT NULL REFERENCES alunos(id)      ON DELETE CASCADE,
    disciplina_id  INT         NOT NULL REFERENCES disciplinas(id) ON DELETE CASCADE,
    semestre       VARCHAR(6)  NOT NULL,
    faltas         INT         NOT NULL DEFAULT 0 CHECK (faltas >= 0),
    UNIQUE (aluno_id, disciplina_id, semestre)
);

CREATE TABLE notas (
    id               SERIAL PRIMARY KEY,
    matricula_id     INT          NOT NULL REFERENCES matriculas(id) ON DELETE CASCADE,
    avaliacao        VARCHAR(40)  NOT NULL,
    valor            NUMERIC(4,2) NOT NULL CHECK (valor BETWEEN 0 AND 10),
    peso             NUMERIC(3,2) NOT NULL CHECK (peso > 0 AND peso <= 1),
    data_lancamento  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE chamados (
    id             SERIAL PRIMARY KEY,
    aluno_id       INT          NOT NULL REFERENCES alunos(id)      ON DELETE CASCADE,
    disciplina_id  INT          NULL     REFERENCES disciplinas(id) ON DELETE SET NULL,
    assunto        VARCHAR(120) NOT NULL,
    descricao      TEXT         NOT NULL,
    status         VARCHAR(15)  NOT NULL DEFAULT 'ABERTO'
                   CHECK (status IN ('ABERTO','EM_ANDAMENTO','RESOLVIDO')),
    criado_em      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);