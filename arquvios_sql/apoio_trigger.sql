CREATE TABLE log_alteracao_notas (
    id            SERIAL PRIMARY KEY,
    nota_id       INT          NOT NULL,
    matricula_id  INT          NOT NULL,
    avaliacao     VARCHAR(40)  NOT NULL,
    operacao      VARCHAR(10)  NOT NULL CHECK (operacao IN ('UPDATE','DELETE')),
    valor_antigo  NUMERIC(4,2),
    valor_novo    NUMERIC(4,2),
    peso_antigo   NUMERIC(3,2),
    peso_novo     NUMERIC(3,2),
    usuario       VARCHAR(100) NOT NULL,
    alterado_em   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE alertas (
    id            SERIAL PRIMARY KEY,
    aluno_id      INT          NOT NULL REFERENCES alunos(id)     ON DELETE CASCADE,
    matricula_id  INT          NOT NULL REFERENCES matriculas(id) ON DELETE CASCADE,
    tipo          VARCHAR(30)  NOT NULL,
    mensagem      VARCHAR(255) NOT NULL,
    media         NUMERIC(4,2),
    ativo         BOOLEAN      NOT NULL DEFAULT TRUE,
    criado_em     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);