INSERT INTO alunos (matricula, nome, email, curso, data_ingresso) VALUES
('20260001', 'Ana Beatriz Souza',   'ana.souza@smartcampus.edu',        'Ciência da Computação',  '2025-02-03'),
('20260002', 'Bruno Henrique Lima', 'bruno.lima@smartcampus.edu',       'Ciência da Computação',  '2025-02-03'),
('20260003', 'Carla Mendes',        'carla.mendes@smartcampus.edu',     'Sistemas de Informação', '2024-08-05'),
('20260004', 'Diego Ferreira',      'diego.ferreira@smartcampus.edu',   'Sistemas de Informação', '2024-08-05'),
('20260005', 'Eduarda Nogueira',    'eduarda.nogueira@smartcampus.edu', 'Ciência da Computação',  '2025-02-03'),
('20260006', 'Felipe Araújo',       'felipe.araujo@smartcampus.edu',    'Engenharia de Software', '2025-08-04');

INSERT INTO disciplinas (codigo, nome, professor, carga_horaria, total_aulas) VALUES
('BD101', 'Banco de Dados',          'Prof. Marcos Teixeira', 80, 40),
('IA201', 'Inteligência Artificial', 'Profa. Helena Duarte',  80, 40),
('ED102', 'Estruturas de Dados',     'Prof. Ricardo Alves',   80, 40),
('ES301', 'Engenharia de Software',  'Profa. Camila Prado',   80, 40);

INSERT INTO matriculas (aluno_id, disciplina_id, semestre, faltas) VALUES
(1, 1, '2026.2', 2),   -- id 1  Ana     - BD
(1, 2, '2026.2', 1),   -- id 2  Ana     - IA
(1, 3, '2026.2', 0),   -- id 3  Ana     - ED
(2, 1, '2026.2', 6),   -- id 4  Bruno   - BD
(2, 2, '2026.2', 3),   -- id 5  Bruno   - IA
(2, 4, '2026.2', 2),   -- id 6  Bruno   - ES
(3, 1, '2026.2', 4),   -- id 7  Carla   - BD
(3, 2, '2026.2', 0),   -- id 8  Carla   - IA
(3, 4, '2026.2', 1),   -- id 9  Carla   - ES
(4, 1, '2026.2', 11),  -- id 10 Diego   - BD (acima do limite de 10 faltas)
(4, 3, '2026.2', 5),   -- id 11 Diego   - ED
(5, 1, '2026.2', 0),   -- id 12 Eduarda - BD
(5, 2, '2026.2', 1),   -- id 13 Eduarda - IA
(6, 1, '2026.2', 8),   -- id 14 Felipe  - BD
(6, 3, '2026.2', 3),   -- id 15 Felipe  - ED
(6, 4, '2026.2', 4);   -- id 16 Felipe  - ES

INSERT INTO notas (matricula_id, avaliacao, valor, peso) VALUES
-- Banco de Dados (só a P1 foi lançada)
(1, 'P1', 8.50, 0.30), (4, 'P1', 4.50, 0.30), (7, 'P1', 6.00, 0.30),
(10,'P1', 3.00, 0.30), (12,'P1', 9.00, 0.30), (14,'P1', 5.50, 0.30),
-- Inteligência Artificial
(2, 'AV1', 7.00, 0.50), (5, 'AV1', 5.00, 0.50), (8, 'AV1', 8.00, 0.50), (13,'AV1', 9.50, 0.50),
-- Estruturas de Dados
(3, 'Prova 1', 9.00, 0.50), (3, 'Trabalho 1', 8.00, 0.50),
(11,'Prova 1', 5.00, 0.50), (11,'Trabalho 1', 4.00, 0.50),
(15,'Prova 1', 6.50, 0.50), (15,'Trabalho 1', 7.00, 0.50),
-- Engenharia de Software
(6, 'AV1', 6.50, 0.40), (9, 'AV1', 7.50, 0.40), (16,'AV1', 4.00, 0.40);

INSERT INTO chamados (aluno_id, disciplina_id, assunto, descricao, status) VALUES
(2, 1, 'Revisão da nota da P1',  'Gostaria de ver a correção da questão 3 da P1 de Banco de Dados.', 'EM_ANDAMENTO'),
(4, 1, 'Justificativa de faltas','Tive atestado médico em duas aulas e quero justificar as faltas.',  'ABERTO'),
(1, 3, 'Dúvida sobre o trabalho','O trabalho de Estruturas de Dados pode ser feito em dupla?',        'RESOLVIDO');