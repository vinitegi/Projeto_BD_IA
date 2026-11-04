-- auxiliar: cria, atualiza ou encerra o alerta de média baixa
CREATE FUNCTION fn_verificar_alerta_media(p_matricula_id INT)
RETURNS VOID
LANGUAGE plpgsql AS $$
DECLARE
    v_media      NUMERIC(4,2);
    v_aluno      INT;
    v_disciplina VARCHAR;
    v_msg        VARCHAR;
BEGIN
    v_media := fn_media_matricula(p_matricula_id);

    IF v_media IS NOT NULL AND v_media < 6.00 THEN
        SELECT m.aluno_id, d.nome
          INTO v_aluno, v_disciplina
          FROM matriculas m
          JOIN disciplinas d ON d.id = m.disciplina_id
         WHERE m.id = p_matricula_id;

        v_msg := 'Sua media parcial em ' || v_disciplina || ' esta em ' || v_media
                 || ', abaixo da minima de 6.00.';

        UPDATE alertas
           SET media = v_media, mensagem = v_msg, criado_em = NOW()
         WHERE matricula_id = p_matricula_id AND tipo = 'MEDIA_BAIXA' AND ativo;

        IF NOT FOUND THEN
            INSERT INTO alertas (aluno_id, matricula_id, tipo, mensagem, media)
            VALUES (v_aluno, p_matricula_id, 'MEDIA_BAIXA', v_msg, v_media);
        END IF;
    ELSE
        UPDATE alertas SET ativo = FALSE
         WHERE matricula_id = p_matricula_id AND tipo = 'MEDIA_BAIXA' AND ativo;
    END IF;
END;
$$;

-- TRIGGER 1 e 2: auditoria (UPDATE e DELETE) na mesma function, separada por TG_OP
CREATE FUNCTION trg_fn_auditoria_notas()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.valor IS DISTINCT FROM NEW.valor OR OLD.peso IS DISTINCT FROM NEW.peso THEN
            INSERT INTO log_alteracao_notas
                (nota_id, matricula_id, avaliacao, operacao,
                 valor_antigo, valor_novo, peso_antigo, peso_novo, usuario)
            VALUES
                (OLD.id, OLD.matricula_id, OLD.avaliacao, 'UPDATE',
                 OLD.valor, NEW.valor, OLD.peso, NEW.peso, CURRENT_USER);
        END IF;
        RETURN NEW;
    ELSE  -- DELETE
        INSERT INTO log_alteracao_notas
            (nota_id, matricula_id, avaliacao, operacao,
             valor_antigo, valor_novo, peso_antigo, peso_novo, usuario)
        VALUES
            (OLD.id, OLD.matricula_id, OLD.avaliacao, 'DELETE',
             OLD.valor, NULL, OLD.peso, NULL, CURRENT_USER);
        RETURN OLD;
    END IF;
END;
$$;

CREATE TRIGGER trg_notas_auditoria
AFTER UPDATE OR DELETE ON notas
FOR EACH ROW EXECUTE FUNCTION trg_fn_auditoria_notas();

-- TRIGGER 3: alerta de média baixa ao lançar ou alterar nota
CREATE FUNCTION trg_fn_alerta_media()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM fn_verificar_alerta_media(NEW.matricula_id);
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notas_alerta
AFTER INSERT OR UPDATE ON notas
FOR EACH ROW EXECUTE FUNCTION trg_fn_alerta_media();