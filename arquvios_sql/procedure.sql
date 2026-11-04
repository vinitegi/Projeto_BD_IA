-- PROCEDURE 1: calcula media e situação de uma matricula
CREATE PROCEDURE sp_calcular_media(
    IN  p_matricula_id INT,
    OUT p_media        NUMERIC,
    OUT p_situacao     VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_faltas INT;
    v_total  INT;
BEGIN
    SELECT m.faltas, d.total_aulas
      INTO v_faltas, v_total
      FROM matriculas m
      JOIN disciplinas d ON d.id = m.disciplina_id
     WHERE m.id = p_matricula_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Matricula % inexistente', p_matricula_id;
    END IF;

    p_media    := fn_media_matricula(p_matricula_id);
    p_situacao := fn_situacao(p_media, v_faltas, v_total);
END;
$$;

-- PROCEDURE 2: abre um chamado e devolve o id gerado
CREATE PROCEDURE sp_abrir_chamado(
    IN  p_aluno_id      INT,
    IN  p_disciplina_id INT,
    IN  p_assunto       VARCHAR,
    IN  p_descricao     TEXT,
    OUT p_chamado_id    INT
)
LANGUAGE plpgsql AS $$
BEGIN
    IF p_assunto IS NULL OR TRIM(p_assunto) = '' THEN
        RAISE EXCEPTION 'Assunto do chamado e obrigatorio';
    END IF;

    INSERT INTO chamados (aluno_id, disciplina_id, assunto, descricao)
    VALUES (p_aluno_id, p_disciplina_id, p_assunto, COALESCE(p_descricao, ''))
    RETURNING id INTO p_chamado_id;
END;
$$;

-- BOLETIM: no Postgres, quem devolve tabela é function
CREATE FUNCTION sp_gerar_boletim(p_aluno_id INT, p_semestre VARCHAR DEFAULT NULL)
RETURNS TABLE (
    codigo       VARCHAR,
    disciplina   VARCHAR,
    semestre     VARCHAR,
    media        NUMERIC,
    faltas       INT,
    total_aulas  INT,
    situacao     VARCHAR
)
LANGUAGE sql STABLE AS $$
    SELECT d.codigo,
           d.nome,
           m.semestre,
           fn_media_matricula(m.id),
           m.faltas,
           d.total_aulas,
           fn_situacao(fn_media_matricula(m.id), m.faltas, d.total_aulas)
      FROM matriculas m
      JOIN disciplinas d ON d.id = m.disciplina_id
     WHERE m.aluno_id = p_aluno_id
       AND (p_semestre IS NULL OR p_semestre = '' OR m.semestre = p_semestre)
     ORDER BY d.nome;
$$;