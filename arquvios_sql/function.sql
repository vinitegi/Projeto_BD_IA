-- media ponderada de uma matrícula (NULL se não tem notas)
CREATE FUNCTION fn_media_matricula(p_matricula_id INT)
RETURNS NUMERIC(4,2)
LANGUAGE sql STABLE AS $$
    SELECT ROUND(SUM(valor * peso) / SUM(peso), 2)
      FROM notas
     WHERE matricula_id = p_matricula_id;
$$;

-- situação: media minima 6,0 e max de 25% de faltas
CREATE FUNCTION fn_situacao(p_media NUMERIC, p_faltas INT, p_total_aulas INT)
RETURNS VARCHAR
LANGUAGE plpgsql IMMUTABLE AS $$
BEGIN
    IF p_faltas > p_total_aulas * 0.25 THEN
        RETURN 'REPROVADO POR FALTAS';
    ELSIF p_media IS NULL THEN
        RETURN 'SEM NOTAS';
    ELSIF p_media >= 6.00 THEN
        RETURN 'REGULAR';
    ELSE
        RETURN 'EM RISCO';
    END IF;
END;
$$;