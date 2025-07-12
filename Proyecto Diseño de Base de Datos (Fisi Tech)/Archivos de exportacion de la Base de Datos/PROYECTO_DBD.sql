CREATE DATABASE proyecto_minam;
USE proyecto_minam;

-- 1. Temas ambientales
CREATE TABLE Topic (
  id_topic VARCHAR(10) PRIMARY KEY,
  topic_name VARCHAR(30) NOT NULL,
  description_t VARCHAR(100)
);

-- 2. Banco de preguntas
CREATE TABLE Question_Bank (
  id_questionbank VARCHAR(10) PRIMARY KEY,
  fk_topic VARCHAR(10) NOT NULL,
  qb_name VARCHAR(40) NOT NULL,
  description_qb VARCHAR(100),
  FOREIGN KEY (fk_topic) REFERENCES Topic(id_topic)
);

-- 3. Nivel de dificultad
CREATE TABLE Difficulty_Level (
  id_difficulty VARCHAR(10) PRIMARY KEY,
  name_difficulty VARCHAR(30) NOT NULL,
  description_dl VARCHAR(200)
);

-- 4. Nivel educativo
CREATE TABLE Education_Level (
  id_educationlevel VARCHAR(10) PRIMARY KEY,
  name_educationlvl VARCHAR(30) NOT NULL,
  description_el VARCHAR(200)
);

-- 5. Usuarios
CREATE TABLE User_ (
  id_user VARCHAR(10) PRIMARY KEY,
  full_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  middle_name VARCHAR(20) NOT NULL,
  email VARCHAR(50) NOT NULL UNIQUE,
  password_u VARCHAR(100) NOT NULL,
  fk_educationlevel VARCHAR(10) NOT NULL,
  FOREIGN KEY (fk_educationlevel) REFERENCES Education_Level(id_educationlevel)
);

-- 6. Nivel de logro
CREATE TABLE Achievement_lvl (
  id_achvlvl VARCHAR(15) PRIMARY KEY,
  name_a VARCHAR(30) NOT NULL,
  description_a VARCHAR(200)
);

-- 7. Preguntas
CREATE TABLE Question (
  id_question VARCHAR(10) PRIMARY KEY,
  fk_questionbank VARCHAR(10) NOT NULL,
  fk_difficulty VARCHAR(10) NOT NULL,
  fk_educationlevel VARCHAR(10) NOT NULL,
  question_text VARCHAR(300) NOT NULL,
  FOREIGN KEY (fk_questionbank) REFERENCES Question_Bank(id_questionbank),
  FOREIGN KEY (fk_difficulty) REFERENCES Difficulty_Level(id_difficulty),
  FOREIGN KEY (fk_educationlevel) REFERENCES Education_Level(id_educationlevel)
);

-- 8. Opciones por pregunta
CREATE TABLE Option_ (
  id_option INT AUTO_INCREMENT PRIMARY KEY,
  fk_question VARCHAR(10) NOT NULL,
  option_text VARCHAR(200) NOT NULL,
  is_correct BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (fk_question) REFERENCES Question(id_question)
);

-- 9. Plantilla de evaluación
CREATE TABLE Template (
  id_template VARCHAR(10) PRIMARY KEY,
  template_name VARCHAR(40) NOT NULL,
  description_t VARCHAR(100),
  num_easy_q INT NOT NULL,   -- Cantidad de preguntas fáciles
  num_medium_q INT NOT NULL, -- Cantidad de preguntas intermedias
  num_hard_q INT NOT NULL    -- Cantidad de preguntas difíciles
);

-- 11. Examen
CREATE TABLE Exam (
  id_exam VARCHAR(10) PRIMARY KEY,
  fk_template VARCHAR(10) NOT NULL,
  fk_user VARCHAR(10) NOT NULL,
  application_date DATE NOT NULL,
  attempt INT NOT NULL,
  FOREIGN KEY (fk_template) REFERENCES Template(id_template),
  FOREIGN KEY (fk_user) REFERENCES User_(id_user)
);

-- 12. Resultado
CREATE TABLE Result (
  id_result VARCHAR(15) PRIMARY KEY,
  fk_exam VARCHAR(10) UNIQUE NOT NULL,
  fk_achvlvl VARCHAR(15) NOT NULL,
  total_score INT NOT NULL,
  percentage_correct DECIMAL(5,2) NOT NULL,
  FOREIGN KEY (fk_exam) REFERENCES Exam(id_exam),
  FOREIGN KEY (fk_achvlvl) REFERENCES Achievement_lvl(id_achvlvl)
);

-- 13. Retroalimentación
CREATE TABLE Feedback (
  id_feedback VARCHAR(10) PRIMARY KEY,
  comment VARCHAR(300)
);

-- 14. Respuesta del usuario
CREATE TABLE Answer (
  id_answer VARCHAR(20) PRIMARY KEY,
  fk_exam VARCHAR(10) NOT NULL,
  fk_question VARCHAR(10) NOT NULL,
  fk_feedback VARCHAR(10),
  user_response VARCHAR(100) DEFAULT '',
  partial_score INT DEFAULT 0,
  FOREIGN KEY (fk_exam) REFERENCES Exam(id_exam),
  FOREIGN KEY (fk_question) REFERENCES Question(id_question),
  FOREIGN KEY (fk_feedback) REFERENCES Feedback(id_feedback),
  INDEX idx_answer_exam (fk_exam),  -- Índice para búsquedas por examen
  INDEX idx_answer_question (fk_question)  -- Índice para búsquedas por pregunta
);

-- 15. Tabla temporal para la sesión (se elimina automáticamente al terminar)
CREATE TEMPORARY TABLE IF NOT EXISTS temp_selected_questions (
    question_id VARCHAR(10),
    difficulty VARCHAR(10),
    order_num INT
);

-- Procedimiento para generar exámenes aleatorios

DELIMITER //

CREATE PROCEDURE generar_examen_aleatorio(
    IN p_user_id VARCHAR(10),
    IN p_template_id VARCHAR(10),
    OUT p_exam_id VARCHAR(10)
)
BEGIN
    DECLARE v_num_easy, v_num_medium, v_num_hard INT;
    DECLARE v_exam_id VARCHAR(10);
    DECLARE v_attempt INT;
    
    -- Obtener configuración de la plantilla
    SELECT num_easy_q, num_medium_q, num_hard_q 
    INTO v_num_easy, v_num_medium, v_num_hard
    FROM Template 
    WHERE id_template = p_template_id;
    
    -- Determinar número de intento
    SELECT IFNULL(MAX(attempt), 0) + 1 INTO v_attempt
    FROM Exam
    WHERE fk_user = p_user_id AND fk_template = p_template_id;
    
    -- Generar ID único para el examen
    SET v_exam_id = CONCAT('EX', LPAD(FLOOR(1 + RAND() * 9999), 4, '0'));
    
    -- Crear el examen
    INSERT INTO Exam (id_exam, fk_template, fk_user, application_date, attempt)
    VALUES (v_exam_id, p_template_id, p_user_id, CURDATE(), v_attempt);
    
    -- Insertar preguntas aleatorias según dificultad (versión corregida)
    INSERT INTO Answer (id_answer, fk_exam, fk_question, user_response, partial_score)
    SELECT 
        CONCAT('ANS', LPAD(FLOOR(RAND() * 100000), 5, '0')),
        v_exam_id,
        id_question,
        '',
        0
    FROM (
        (SELECT id_question FROM Question WHERE fk_difficulty = 'D1' ORDER BY RAND() LIMIT v_num_easy)
        UNION ALL
        (SELECT id_question FROM Question WHERE fk_difficulty = 'D2' ORDER BY RAND() LIMIT v_num_medium)
        UNION ALL
        (SELECT id_question FROM Question WHERE fk_difficulty = 'D3' ORDER BY RAND() LIMIT v_num_hard)
    ) AS preguntas_aleatorias;
    
    SET p_exam_id = v_exam_id;
END //

DELIMITER ;

-- Procedimiento para simular respuestas aleatorias

DELIMITER //
CREATE PROCEDURE simular_respuestas(IN p_exam_id VARCHAR(10))
BEGIN
    DECLARE v_question_id VARCHAR(10);
    DECLARE v_correct_option VARCHAR(200);
    DECLARE v_incorrect_option VARCHAR(200);
    DECLARE v_is_correct BOOLEAN;
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE cur CURSOR FOR 
        SELECT q.id_question, o.option_text 
        FROM Question q 
        JOIN Option_ o ON q.id_question = o.fk_question 
        JOIN Answer a ON q.id_question = a.fk_question 
        WHERE a.fk_exam = p_exam_id AND o.is_correct = TRUE;
        
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_question_id, v_correct_option;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Actualizar algunas respuestas como correctas (aleatoriamente)
        SET v_is_correct = (RAND() > 0.3);  -- 70% de probabilidad de responder correctamente
        
        -- Si es incorrecta, seleccionar una opción incorrecta aleatoria
        IF v_is_correct THEN
            UPDATE Answer 
            SET user_response = v_correct_option, 
                partial_score = 1,
                fk_feedback = 'F002'
            WHERE fk_exam = p_exam_id AND fk_question = v_question_id;
        ELSE
            -- Seleccionar una opción incorrecta aleatoria para esta pregunta
            SELECT option_text INTO v_incorrect_option
            FROM Option_
            WHERE fk_question = v_question_id AND is_correct = FALSE
            ORDER BY RAND()
            LIMIT 1;
            
            UPDATE Answer 
            SET user_response = v_incorrect_option, 
                partial_score = 0,
                fk_feedback = 'F001'
            WHERE fk_exam = p_exam_id AND fk_question = v_question_id;
        END IF;
    END LOOP;
    CLOSE cur;
    
    -- Calcular resultado final con ID explícito
    INSERT INTO Result(id_result, fk_exam, fk_achvlvl, total_score, percentage_correct)
    SELECT 
        CONCAT('RES_', p_exam_id),
        p_exam_id,
        CASE 
            WHEN (SUM(a.partial_score) * 100.0 / COUNT(*)) = 100 THEN 'A4'
            WHEN (SUM(a.partial_score) * 100.0 / COUNT(*)) >= 90 THEN 'A3'
            WHEN (SUM(a.partial_score) * 100.0 / COUNT(*)) >= 70 THEN 'A2'
            ELSE 'A1'
        END,
        SUM(a.partial_score),
        (SUM(a.partial_score) * 100.0 / COUNT(*))
    FROM Answer a
    WHERE a.fk_exam = p_exam_id
    ON DUPLICATE KEY UPDATE
        fk_achvlvl = VALUES(fk_achvlvl),
        total_score = VALUES(total_score),
        percentage_correct = VALUES(percentage_correct);
END //
DELIMITER ;

-- Calcular el resultado de una respuesta

DELIMITER //

CREATE PROCEDURE calcular_resultado(IN exam_id VARCHAR(10))
BEGIN
  DECLARE total_correctas INT DEFAULT 0;
  DECLARE total_preguntas INT DEFAULT 0;
  DECLARE porcentaje DECIMAL(5,2) DEFAULT 0;
  DECLARE logro_id VARCHAR(15);
  
  -- Calcular respuestas correctas
  SELECT IFNULL(SUM(partial_score), 0)
  INTO total_correctas
  FROM Answer
  WHERE fk_exam = exam_id;
  
  -- Contar total preguntas en el examen
  SELECT COUNT(*)
  INTO total_preguntas
  FROM Answer
  WHERE fk_exam = exam_id;
  
  -- Calcular porcentaje
  IF total_preguntas = 0 THEN
    SET porcentaje = 0;
  ELSE
    SET porcentaje = (total_correctas * 100.0 / total_preguntas);
  END IF;
  
  -- Determinar nivel de logro
  IF porcentaje = 100 THEN
    SET logro_id = 'A4';
  ELSEIF porcentaje >= 90 THEN
    SET logro_id = 'A3';
  ELSEIF porcentaje >= 70 THEN
    SET logro_id = 'A2';
  ELSE
    SET logro_id = 'A1';
  END IF;
  
  -- Insertar o actualizar resultado
  INSERT INTO Result(id_result, fk_exam, fk_achvlvl, total_score, percentage_correct)
  VALUES (
    CONCAT('RES_', exam_id),
    exam_id,
    logro_id,
    total_correctas,
    porcentaje
  )
  ON DUPLICATE KEY UPDATE
    fk_achvlvl = logro_id,
    total_score = total_correctas,
    percentage_correct = porcentaje;
END //

DELIMITER ;

-- CARGA DE DATOS
INSERT INTO Topic VALUES
('T001', 'Cambio Climático', 'Causas, consecuencias y acciones'),
('T002', 'Residuos Sólidos', 'Gestión y reciclaje de residuos'),
('T003', 'Biodiversidad', 'Conservación de la flora y fauna'),
('T004', 'Energías Renovables', 'Fuentes sostenibles de energía'),
('T005', 'Agua y Saneamiento', 'Uso racional del agua y su tratamiento');

INSERT INTO Question_Bank VALUES
('QB001', 'T001', 'Banco Cambio Climático', 'Preguntas sobre cambio climático'),
('QB002', 'T002', 'Banco Residuos', 'Preguntas sobre clasificación y reciclaje'),
('QB003', 'T003', 'Banco Biodiversidad', 'Conservación y cuidado de la biodiversidad'),
('QB004', 'T004', 'Banco Energía', 'Fuentes energéticas limpias'),
('QB005', 'T005', 'Banco Agua', 'Cuidados del recurso hídrico');

INSERT INTO Difficulty_Level VALUES
('D1', 'Fácil', 'Conocimiento general básico'),
('D2', 'Intermedio', 'Conocimiento técnico medio'),
('D3', 'Difícil', 'Análisis avanzado y crítico');

INSERT INTO Education_Level VALUES
('E1', 'Escolar', 'Primaria y secundaria'),
('E2', 'Universitario', 'Educación superior'),
('E3', 'Ciudadanía', 'Público en general');

-- Preguntas CAMBIO CLIMATICO
INSERT INTO Question VALUES
('Q001', 'QB001', 'D1', 'E1', '¿Qué es el cambio climático?'),
('Q002', 'QB001', 'D1', 'E1', '¿Cuál es el principal gas de efecto invernadero?'),
('Q003', 'QB001', 'D1', 'E3', '¿Qué fenómeno causa aumento del nivel del mar?'),
('Q004', 'QB001', 'D1', 'E3', '¿Qué países sufren más el cambio climático?'),
('Q005', 'QB001', 'D1', 'E1', '¿Cuál de estos es un efecto del cambio climático?'),

('Q006', 'QB001', 'D2', 'E3', '¿Qué acción contribuye más al calentamiento global?'),
('Q007', 'QB001', 'D2', 'E2', '¿Qué acuerdo busca mitigar el cambio climático?'),
('Q008', 'QB001', 'D2', 'E3', '¿Cuál es una consecuencia del derretimiento polar?'),
('Q009', 'QB001', 'D2', 'E3', '¿Qué sector emite más gases contaminantes?'),
('Q010', 'QB001', 'D2', 'E2', '¿Qué es el efecto invernadero?'),

('Q011', 'QB001', 'D3', 'E2', 'Explica una estrategia de mitigación climática.'),
('Q012', 'QB001', 'D3', 'E2', 'Relación entre deforestación y calentamiento global.'),
('Q013', 'QB001', 'D3', 'E2', 'Analiza el impacto del transporte urbano en el clima.'),
('Q014', 'QB001', 'D3', 'E2', '¿Cómo influye el consumo energético en el clima?'),
('Q015', 'QB001', 'D3', 'E2', 'Evalúa la efectividad del Acuerdo de París.');

-- OPCIONES CAMBIO CLIMATICO 
-- Q001
INSERT INTO Option_ VALUES
(NULL, 'Q001', 'Variación del clima a largo plazo', TRUE),
(NULL, 'Q001', 'Tormentas y huracanes', FALSE),
(NULL, 'Q001', 'Cambio de estaciones', FALSE),
(NULL, 'Q001', 'Fenómeno del Niño', FALSE);

-- Q002
INSERT INTO Option_ VALUES
(NULL, 'Q002', 'Dióxido de carbono (CO₂)', TRUE),
(NULL, 'Q002', 'Nitrógeno', FALSE),
(NULL, 'Q002', 'Oxígeno', FALSE),
(NULL, 'Q002', 'Ozono', FALSE);

-- Q003
INSERT INTO Option_ VALUES
(NULL, 'Q003', 'Derretimiento de glaciares', TRUE),
(NULL, 'Q003', 'Erupciones volcánicas', FALSE),
(NULL, 'Q003', 'Tsunamis', FALSE),
(NULL, 'Q003', 'Deforestación', FALSE);

-- Q004
INSERT INTO Option_ VALUES
(NULL, 'Q004', 'Países en desarrollo', TRUE),
(NULL, 'Q004', 'Países ricos', FALSE),
(NULL, 'Q004', 'Europa', FALSE),
(NULL, 'Q004', 'Asia', FALSE);

-- Q005
INSERT INTO Option_ VALUES
(NULL, 'Q005', 'Sequías prolongadas', TRUE),
(NULL, 'Q005', 'Más nevadas en el verano', FALSE),
(NULL, 'Q005', 'Migración de aves', FALSE),
(NULL, 'Q005', 'Más eclipses solares', FALSE);

-- Q006
INSERT INTO Option_ VALUES
(NULL, 'Q006', 'Quema de combustibles fósiles', TRUE),
(NULL, 'Q006', 'Uso de bicicletas', FALSE),
(NULL, 'Q006', 'Filtrar agua', FALSE),
(NULL, 'Q006', 'Cultivar hortalizas', FALSE);

-- Q007
INSERT INTO Option_ VALUES
(NULL, 'Q007', 'Acuerdo de París', TRUE),
(NULL, 'Q007', 'Tratado de Kioto', FALSE),
(NULL, 'Q007', 'Convenio de Ginebra', FALSE),
(NULL, 'Q007', 'Protocolo de Montreal', FALSE);

-- Q008
INSERT INTO Option_ VALUES
(NULL, 'Q008', 'Aumento del nivel del mar', TRUE),
(NULL, 'Q008', 'Mejor clima en invierno', FALSE),
(NULL, 'Q008', 'Más lluvias', FALSE),
(NULL, 'Q008', 'Huracanes constantes', FALSE);

-- Q009
INSERT INTO Option_ VALUES
(NULL, 'Q009', 'Transporte', TRUE),
(NULL, 'Q009', 'Educación', FALSE),
(NULL, 'Q009', 'Pesca artesanal', FALSE),
(NULL, 'Q009', 'Turismo', FALSE);

-- Q010
INSERT INTO Option_ VALUES
(NULL, 'Q010', 'Fenómeno natural que atrapa el calor', TRUE),
(NULL, 'Q010', 'Exceso de lluvias', FALSE),
(NULL, 'Q010', 'Bloqueo solar por gases', FALSE),
(NULL, 'Q010', 'Daño en la capa de ozono', FALSE);

-- Q011
INSERT INTO Option_ VALUES
(NULL, 'Q011', 'Implementar energías renovables', TRUE),
(NULL, 'Q011', 'Aumentar consumo de gas', FALSE),
(NULL, 'Q011', 'Eliminar transporte público', FALSE),
(NULL, 'Q011', 'Construir fábricas nuevas', FALSE);

-- Q012
INSERT INTO Option_ VALUES
(NULL, 'Q012', 'La deforestación reduce la absorción de CO₂', TRUE),
(NULL, 'Q012', 'Los árboles generan CO₂', FALSE),
(NULL, 'Q012', 'No influye en el clima', FALSE),
(NULL, 'Q012', 'Los desiertos atrapan calor', FALSE);

-- Q013
INSERT INTO Option_ VALUES
(NULL, 'Q013', 'El transporte genera CO₂ y contribuye al calentamiento', TRUE),
(NULL, 'Q013', 'Los autos limpian el aire', FALSE),
(NULL, 'Q013', 'No hay impacto del tráfico', FALSE),
(NULL, 'Q013', 'El transporte mejora el clima', FALSE);

-- Q014
INSERT INTO Option_ VALUES
(NULL, 'Q014', 'Mayor consumo energético aumenta emisiones', TRUE),
(NULL, 'Q014', 'La energía no afecta el clima', FALSE),
(NULL, 'Q014', 'El gas natural enfría el ambiente', FALSE),
(NULL, 'Q014', 'La electricidad es neutra', FALSE);

-- Q015
INSERT INTO Option_ VALUES
(NULL, 'Q015', 'Ha generado compromisos reales pero con desafíos', TRUE),
(NULL, 'Q015', 'No ha tenido impacto global', FALSE),
(NULL, 'Q015', 'Solo se firmó sin acciones', FALSE),
(NULL, 'Q015', 'Es un acuerdo de comercio', FALSE);

-- Preguntas RESIDUOS SÓLIDOS
INSERT INTO Question VALUES
('Q101', 'QB002', 'D1', 'E1', '¿Qué es un residuo sólido?'),
('Q102', 'QB002', 'D1', 'E3', '¿Cuál es un ejemplo de residuo orgánico?'),
('Q103', 'QB002', 'D1', 'E1', '¿Qué color de tacho se usa para reciclaje?'),
('Q104', 'QB002', 'D1', 'E1', '¿Qué residuo es inorgánico?'),
('Q105', 'QB002', 'D1', 'E3', '¿Qué hacer con pilas usadas?'),

('Q106', 'QB002', 'D2', 'E2', '¿Qué es el compostaje?'),
('Q107', 'QB002', 'D2', 'E3', '¿Por qué separar residuos?'),
('Q108', 'QB002', 'D2', 'E3', '¿Qué residuos son peligrosos?'),
('Q109', 'QB002', 'D2', 'E3', 'Ejemplo de residuo reutilizable'),
('Q110', 'QB002', 'D2', 'E2', '¿Qué es un relleno sanitario?'),

('Q111', 'QB002', 'D3', 'E2', 'Diseña una campaña de reciclaje.'),
('Q112', 'QB002', 'D3', 'E2', 'Analiza el impacto ambiental de los residuos plásticos.'),
('Q113', 'QB002', 'D3', 'E2', 'Evalúa las ventajas del reciclaje en una comunidad.'),
('Q114', 'QB002', 'D3', 'E2', 'Propuesta para reducir residuos en tu escuela.'),
('Q115', 'QB002', 'D3', 'E2', 'Relación entre residuos sólidos y salud pública.');

-- Q101
INSERT INTO Option_ VALUES
(NULL, 'Q101', 'Material que se descarta como basura', TRUE),
(NULL, 'Q101', 'Gotas de lluvia', FALSE),
(NULL, 'Q101', 'Luz solar', FALSE),
(NULL, 'Q101', 'Vapor de agua', FALSE);

-- Q102
INSERT INTO Option_ VALUES
(NULL, 'Q102', 'Cáscaras de frutas', TRUE),
(NULL, 'Q102', 'Clavos', FALSE),
(NULL, 'Q102', 'Vidrio', FALSE),
(NULL, 'Q102', 'Papel aluminio', FALSE);

-- Q103
INSERT INTO Option_ VALUES
(NULL, 'Q103', 'Verde', TRUE),
(NULL, 'Q103', 'Rojo', FALSE),
(NULL, 'Q103', 'Azul', FALSE),
(NULL, 'Q103', 'Negro', FALSE);

-- Q104
INSERT INTO Option_ VALUES
(NULL, 'Q104', 'Botellas de plástico', TRUE),
(NULL, 'Q104', 'Restos de comida', FALSE),
(NULL, 'Q104', 'Cáscaras de plátano', FALSE),
(NULL, 'Q104', 'Hojas secas', FALSE);

-- Q105
INSERT INTO Option_ VALUES
(NULL, 'Q105', 'Llevarlas a puntos de acopio', TRUE),
(NULL, 'Q105', 'Botarlas al río', FALSE),
(NULL, 'Q105', 'Quemarlas en casa', FALSE),
(NULL, 'Q105', 'Tirarlas en el jardín', FALSE);

-- Q106
INSERT INTO Option_ VALUES
(NULL, 'Q106', 'Transformar residuos orgánicos en abono', TRUE),
(NULL, 'Q106', 'Clasificar metales', FALSE),
(NULL, 'Q106', 'Quemar basura', FALSE),
(NULL, 'Q106', 'Congelar desechos', FALSE);

-- Q107
INSERT INTO Option_ VALUES
(NULL, 'Q107', 'Para facilitar el reciclaje', TRUE),
(NULL, 'Q107', 'Para ensuciar menos', FALSE),
(NULL, 'Q107', 'Para gastar más bolsas', FALSE),
(NULL, 'Q107', 'Para hacer ejercicio', FALSE);

-- Q108
INSERT INTO Option_ VALUES
(NULL, 'Q108', 'Pilas y electrónicos', TRUE),
(NULL, 'Q108', 'Cáscaras de naranja', FALSE),
(NULL, 'Q108', 'Papel usado', FALSE),
(NULL, 'Q108', 'Cartón mojado', FALSE);

-- Q109
INSERT INTO Option_ VALUES
(NULL, 'Q109', 'Frascos de vidrio', TRUE),
(NULL, 'Q109', 'Cáscaras de huevo', FALSE),
(NULL, 'Q109', 'Comida descompuesta', FALSE),
(NULL, 'Q109', 'Aserrín', FALSE);

-- Q110
INSERT INTO Option_ VALUES
(NULL, 'Q110', 'Lugar donde se depositan y cubren los residuos', TRUE),
(NULL, 'Q110', 'Parque recreativo', FALSE),
(NULL, 'Q110', 'Depósito de agua potable', FALSE),
(NULL, 'Q110', 'Jardín botánico', FALSE);

-- Q111
INSERT INTO Option_ VALUES
(NULL, 'Q111', 'Realizar charlas y colocar tachos diferenciados', TRUE),
(NULL, 'Q111', 'Quemar residuos en el patio', FALSE),
(NULL, 'Q111', 'Enterrar todo tipo de basura', FALSE),
(NULL, 'Q111', 'No hacer nada y esperar que otros limpien', FALSE);

-- Q112
INSERT INTO Option_ VALUES
(NULL, 'Q112', 'Los plásticos contaminan mares y demoran en degradarse', TRUE),
(NULL, 'Q112', 'Los plásticos se disuelven rápido', FALSE),
(NULL, 'Q112', 'No afectan a los animales', FALSE),
(NULL, 'Q112', 'Mejoran la calidad del suelo', FALSE);

-- Q113
INSERT INTO Option_ VALUES
(NULL, 'Q113', 'Reduce basura, mejora limpieza y conciencia ambiental', TRUE),
(NULL, 'Q113', 'Ocupa más espacio en las calles', FALSE),
(NULL, 'Q113', 'No tiene beneficios', FALSE),
(NULL, 'Q113', 'Es muy costoso e inútil', FALSE);

-- Q114
INSERT INTO Option_ VALUES
(NULL, 'Q114', 'Colocar puntos de reciclaje y educar a los alumnos', TRUE),
(NULL, 'Q114', 'Tirar la basura al patio', FALSE),
(NULL, 'Q114', 'Eliminar tachos', FALSE),
(NULL, 'Q114', 'No hacer campañas', FALSE);

-- Q115
INSERT INTO Option_ VALUES
(NULL, 'Q115', 'La mala gestión de residuos puede generar enfermedades', TRUE),
(NULL, 'Q115', 'La basura no tiene relación con la salud', FALSE),
(NULL, 'Q115', 'Mientras más residuos, mejor', FALSE),
(NULL, 'Q115', 'Solo importa en las ciudades grandes', FALSE);

-- Preguntas BIODIVERSIDAD
INSERT INTO Question VALUES
('Q201', 'QB003', 'D1', 'E1', '¿Qué es la biodiversidad?'),
('Q202', 'QB003', 'D1', 'E3', '¿Qué animal emblemático del Perú está en peligro de extinción?'),
('Q203', 'QB003', 'D1', 'E1', '¿Qué es un ecosistema?'),
('Q204', 'QB003', 'D1', 'E1', '¿Qué es una especie endémica?'),
('Q205', 'QB003', 'D1', 'E1', '¿Qué planta peruana está en peligro de extinción?'),

('Q206', 'QB003', 'D2', 'E2', '¿Qué actividad humana afecta más la biodiversidad?'),
('Q207', 'QB003', 'D2', 'E3', '¿Qué es conservación ex situ?'),
('Q208', 'QB003', 'D2', 'E3', '¿Qué impacto tiene la minería ilegal en la biodiversidad?'),
('Q209', 'QB003', 'D2', 'E3', '¿Qué es un corredor biológico?'),
('Q210', 'QB003', 'D2', 'E2', '¿Por qué es importante preservar la biodiversidad?'),

('Q211', 'QB003', 'D3', 'E2', 'Analiza la relación entre biodiversidad y salud humana.'),
('Q212', 'QB003', 'D3', 'E2', 'Propón una política para conservar especies en peligro.'),
('Q213', 'QB003', 'D3', 'E2', 'Evalúa el papel de las áreas naturales protegidas.'),
('Q214', 'QB003', 'D3', 'E2', 'Justifica la necesidad de preservar la Amazonía.'),
('Q215', 'QB003', 'D3', 'E2', 'Reflexiona sobre el equilibrio ecológico y su pérdida.');

-- Q201
INSERT INTO Option_ VALUES
(NULL, 'Q201', 'Variedad de seres vivos en un ecosistema', TRUE),
(NULL, 'Q201', 'Cantidad de personas en un país', FALSE),
(NULL, 'Q201', 'Diversidad de minerales', FALSE),
(NULL, 'Q201', 'Cantidad de árboles por bosque', FALSE);

-- Q202
INSERT INTO Option_ VALUES
(NULL, 'Q202', 'Oso andino', TRUE),
(NULL, 'Q202', 'Gallina', FALSE),
(NULL, 'Q202', 'Caballo', FALSE),
(NULL, 'Q202', 'Gato montés', FALSE);

-- Q203
INSERT INTO Option_ VALUES
(NULL, 'Q203', 'Conjunto de seres vivos y su entorno', TRUE),
(NULL, 'Q203', 'Una especie rara', FALSE),
(NULL, 'Q203', 'Un tipo de planta', FALSE),
(NULL, 'Q203', 'Un parque natural', FALSE);

-- Q204
INSERT INTO Option_ VALUES
(NULL, 'Q204', 'Solo vive en una región específica', TRUE),
(NULL, 'Q204', 'Es común en todo el mundo', FALSE),
(NULL, 'Q204', 'No tiene hábitat definido', FALSE),
(NULL, 'Q204', 'Está en peligro crítico', FALSE);

-- Q205
INSERT INTO Option_ VALUES
(NULL, 'Q205', 'Puya Raimondi', TRUE),
(NULL, 'Q205', 'Cactus de jardín', FALSE),
(NULL, 'Q205', 'Palmera datilera', FALSE),
(NULL, 'Q205', 'Orquídea común', FALSE);

-- Q206
INSERT INTO Option_ VALUES
(NULL, 'Q206', 'Deforestación', TRUE),
(NULL, 'Q206', 'Reforestación', FALSE),
(NULL, 'Q206', 'Turismo ecológico', FALSE),
(NULL, 'Q206', 'Educación ambiental', FALSE);

-- Q207
INSERT INTO Option_ VALUES
(NULL, 'Q207', 'Conservación fuera del hábitat natural', TRUE),
(NULL, 'Q207', 'Protección dentro del ecosistema', FALSE),
(NULL, 'Q207', 'Destrucción de especies invasoras', FALSE),
(NULL, 'Q207', 'Cuidado de zonas urbanas', FALSE);

-- Q208
INSERT INTO Option_ VALUES
(NULL, 'Q208', 'Destruye hábitats y contamina ecosistemas', TRUE),
(NULL, 'Q208', 'Crea nuevos refugios naturales', FALSE),
(NULL, 'Q208', 'Mejora el acceso al agua', FALSE),
(NULL, 'Q208', 'Reduce la deforestación', FALSE);

-- Q209
INSERT INTO Option_ VALUES
(NULL, 'Q209', 'Conexión entre áreas naturales para especies', TRUE),
(NULL, 'Q209', 'Carretera entre ciudades', FALSE),
(NULL, 'Q209', 'Camino para turistas', FALSE),
(NULL, 'Q209', 'Zona sin vegetación', FALSE);

-- Q210
INSERT INTO Option_ VALUES
(NULL, 'Q210', 'Garantiza recursos y equilibrio ecológico', TRUE),
(NULL, 'Q210', 'Genera más residuos', FALSE),
(NULL, 'Q210', 'Reduce el turismo', FALSE),
(NULL, 'Q210', 'Impide el desarrollo urbano', FALSE);

-- Q211
INSERT INTO Option_ VALUES
(NULL, 'Q211', 'Mayor biodiversidad favorece salud y medicina', TRUE),
(NULL, 'Q211', 'La biodiversidad enferma a las personas', FALSE),
(NULL, 'Q211', 'No tiene relación alguna', FALSE),
(NULL, 'Q211', 'Solo afecta a los animales', FALSE);

-- Q212
INSERT INTO Option_ VALUES
(NULL, 'Q212', 'Crear leyes y proteger hábitats naturales', TRUE),
(NULL, 'Q212', 'Eliminar todos los animales peligrosos', FALSE),
(NULL, 'Q212', 'Reducir zonas verdes', FALSE),
(NULL, 'Q212', 'Cerrar parques nacionales', FALSE);

-- Q213
INSERT INTO Option_ VALUES
(NULL, 'Q213', 'Protegen especies y fomentan educación ambiental', TRUE),
(NULL, 'Q213', 'Son espacios comerciales', FALSE),
(NULL, 'Q213', 'Son zonas sin vida', FALSE),
(NULL, 'Q213', 'No cumplen funciones útiles', FALSE);

-- Q214
INSERT INTO Option_ VALUES
(NULL, 'Q214', 'Alberga gran biodiversidad y regula el clima', TRUE),
(NULL, 'Q214', 'Solo es útil para turismo', FALSE),
(NULL, 'Q214', 'No influye en el ambiente', FALSE),
(NULL, 'Q214', 'Es un desierto tropical', FALSE);

-- Q215
INSERT INTO Option_ VALUES
(NULL, 'Q215', 'Su pérdida afecta a todos los seres vivos', TRUE),
(NULL, 'Q215', 'No cambia nada', FALSE),
(NULL, 'Q215', 'Solo afecta a las aves', FALSE),
(NULL, 'Q215', 'Mejora el crecimiento urbano', FALSE);

-- Preguntas ENERGÍA Y RECURSOS
INSERT INTO Question VALUES
('Q301', 'QB004', 'D1', 'E1', '¿Qué es energía renovable?'),
('Q302', 'QB004', 'D1', 'E1', '¿Cuál de estos es un tipo de energía renovable?'),
('Q303', 'QB004', 'D1', 'E3', '¿Qué fuente de energía utiliza el sol?'),
('Q304', 'QB004', 'D1', 'E3', '¿Qué fuente de energía usa el viento?'),
('Q305', 'QB004', 'D1', 'E1', '¿Qué es energía hidráulica?'),

('Q306', 'QB004', 'D2', 'E3', '¿Qué es eficiencia energética?'),
('Q307', 'QB004', 'D2', 'E2', '¿Qué es huella de carbono?'),
('Q308', 'QB004', 'D2', 'E3', '¿Cómo reducir el consumo energético en casa?'),
('Q309', 'QB004', 'D2', 'E3', '¿Por qué se deben usar focos LED?'),
('Q310', 'QB004', 'D2', 'E2', '¿Qué país lidera el uso de energía solar?'),

('Q311', 'QB004', 'D3', 'E2', 'Evalúa el impacto ambiental de los combustibles fósiles.'),
('Q312', 'QB004', 'D3', 'E2', 'Diseña una campaña de ahorro energético.'),
('Q313', 'QB004', 'D3', 'E2', 'Analiza la matriz energética del Perú.'),
('Q314', 'QB004', 'D3', 'E2', 'Propón políticas públicas para promover energía limpia.'),
('Q315', 'QB004', 'D3', 'E2', 'Discute los retos del cambio a energías sostenibles.');

-- Q301
INSERT INTO Option_ VALUES
(NULL, 'Q301', 'Energía que se regenera naturalmente', TRUE),
(NULL, 'Q301', 'Energía limitada', FALSE),
(NULL, 'Q301', 'Energía de combustibles', FALSE),
(NULL, 'Q301', 'Electricidad contaminante', FALSE);

-- Q302
INSERT INTO Option_ VALUES
(NULL, 'Q302', 'Energía solar', TRUE),
(NULL, 'Q302', 'Energía de carbón', FALSE),
(NULL, 'Q302', 'Energía nuclear', FALSE),
(NULL, 'Q302', 'Gas natural', FALSE);

-- Q303
INSERT INTO Option_ VALUES
(NULL, 'Q303', 'Energía solar', TRUE),
(NULL, 'Q303', 'Energía eólica', FALSE),
(NULL, 'Q303', 'Energía geotérmica', FALSE),
(NULL, 'Q303', 'Energía hidráulica', FALSE);

-- Q304
INSERT INTO Option_ VALUES
(NULL, 'Q304', 'Energía eólica', TRUE),
(NULL, 'Q304', 'Energía fósil', FALSE),
(NULL, 'Q304', 'Energía térmica', FALSE),
(NULL, 'Q304', 'Energía nuclear', FALSE);

-- Q305
INSERT INTO Option_ VALUES
(NULL, 'Q305', 'Energía del agua en movimiento', TRUE),
(NULL, 'Q305', 'Energía de alimentos', FALSE),
(NULL, 'Q305', 'Energía del petróleo', FALSE),
(NULL, 'Q305', 'Energía de gases tóxicos', FALSE);

-- Q306
INSERT INTO Option_ VALUES
(NULL, 'Q306', 'Uso inteligente de la energía', TRUE),
(NULL, 'Q306', 'Aumentar consumo', FALSE),
(NULL, 'Q306', 'Solo energía solar', FALSE),
(NULL, 'Q306', 'Gastar más luz', FALSE);

-- Q307
INSERT INTO Option_ VALUES
(NULL, 'Q307', 'Cantidad de gases de efecto invernadero que emite una persona o actividad', TRUE),
(NULL, 'Q307', 'Marca de huellas en el suelo', FALSE),
(NULL, 'Q307', 'Huella en la arena', FALSE),
(NULL, 'Q307', 'Gasto de dinero en energía', FALSE);

-- Q308
INSERT INTO Option_ VALUES
(NULL, 'Q308', 'Apagar luces innecesarias y usar LED', TRUE),
(NULL, 'Q308', 'Encender todo el día', FALSE),
(NULL, 'Q308', 'Usar focos incandescentes', FALSE),
(NULL, 'Q308', 'Dejar electrodomésticos encendidos', FALSE);

-- Q309
INSERT INTO Option_ VALUES
(NULL, 'Q309', 'Consumen menos energía y duran más', TRUE),
(NULL, 'Q309', 'Dan poca luz', FALSE),
(NULL, 'Q309', 'Son peligrosos', FALSE),
(NULL, 'Q309', 'Calientan más el ambiente', FALSE);

-- Q310
INSERT INTO Option_ VALUES
(NULL, 'Q310', 'China', TRUE),
(NULL, 'Q310', 'Perú', FALSE),
(NULL, 'Q310', 'Brasil', FALSE),
(NULL, 'Q310', 'Alemania', FALSE);

-- Q311
INSERT INTO Option_ VALUES
(NULL, 'Q311', 'Contaminan el aire y contribuyen al cambio climático', TRUE),
(NULL, 'Q311', 'Son limpios y naturales', FALSE),
(NULL, 'Q311', 'Reducen la contaminación', FALSE),
(NULL, 'Q311', 'Ayudan a enfriar el planeta', FALSE);

-- Q312
INSERT INTO Option_ VALUES
(NULL, 'Q312', 'Promover uso de LED y educación energética', TRUE),
(NULL, 'Q312', 'Aumentar propaganda eléctrica', FALSE),
(NULL, 'Q312', 'Distribuir focos viejos', FALSE),
(NULL, 'Q312', 'Fomentar uso de calefacción constante', FALSE);

-- Q313
INSERT INTO Option_ VALUES
(NULL, 'Q313', 'Predominio de hidroenergía y poco uso solar', TRUE),
(NULL, 'Q313', '100% energía nuclear', FALSE),
(NULL, 'Q313', 'Solo energías fósiles', FALSE),
(NULL, 'Q313', 'Matriz completamente solar', FALSE);

-- Q314
INSERT INTO Option_ VALUES
(NULL, 'Q314', 'Subsidios a renovables y campañas educativas', TRUE),
(NULL, 'Q314', 'Reducir impuestos al petróleo', FALSE),
(NULL, 'Q314', 'Prohibir paneles solares', FALSE),
(NULL, 'Q314', 'Privatizar todo el sistema energético', FALSE);

-- Q315
INSERT INTO Option_ VALUES
(NULL, 'Q315', 'Falta de inversión, resistencia y cambio cultural', TRUE),
(NULL, 'Q315', 'No hay retos', FALSE),
(NULL, 'Q315', 'Las renovables contaminan más', FALSE),
(NULL, 'Q315', 'Todo ya es sostenible', FALSE);

-- Preguntas AGUA Y SANEAMIENTO
INSERT INTO Question VALUES
('Q401', 'QB005', 'D1', 'E1', '¿Por qué es importante el agua?'),
('Q402', 'QB005', 'D1', 'E3', '¿Cuánto del cuerpo humano es agua?'),
('Q403', 'QB005', 'D1', 'E1', '¿Qué es agua potable?'),
('Q404', 'QB005', 'D1', 'E3', '¿Qué elementos contaminan el agua?'),
('Q405', 'QB005', 'D1', 'E3', '¿Qué es un acuífero?'),

('Q406', 'QB005', 'D2', 'E2', '¿Qué es saneamiento básico?'),
('Q407', 'QB005', 'D2', 'E3', '¿Qué es una planta de tratamiento de agua?'),
('Q408', 'QB005', 'D2', 'E2', '¿Por qué es importante el acceso al agua segura?'),
('Q409', 'QB005', 'D2', 'E3', '¿Cómo proteger una cuenca hidrográfica?'),
('Q410', 'QB005', 'D2', 'E3', '¿Qué impacto tiene la escasez de agua?'),

('Q411', 'QB005', 'D3', 'E2', 'Analiza las causas de la contaminación del agua.'),
('Q412', 'QB005', 'D3', 'E2', 'Propón acciones para ahorrar agua en la ciudad.'),
('Q413', 'QB005', 'D3', 'E2', 'Evalúa el papel del Estado en la gestión del agua.'),
('Q414', 'QB005', 'D3', 'E2', 'Discute la relación entre agua y salud pública.'),
('Q415', 'QB005', 'D3', 'E2', 'Reflexiona sobre el agua como derecho humano.');

-- Q401
INSERT INTO Option_ VALUES
(NULL, 'Q401', 'Es esencial para la vida', TRUE),
(NULL, 'Q401', 'Sirve solo para lavar', FALSE),
(NULL, 'Q401', 'Solo se usa en fábricas', FALSE),
(NULL, 'Q401', 'Es reemplazable por refrescos', FALSE);

-- Q402
INSERT INTO Option_ VALUES
(NULL, 'Q402', 'Aproximadamente 70%', TRUE),
(NULL, 'Q402', '10%', FALSE),
(NULL, 'Q402', '30%', FALSE),
(NULL, 'Q402', '90%', FALSE);

-- Q403
INSERT INTO Option_ VALUES
(NULL, 'Q403', 'Agua apta para el consumo humano', TRUE),
(NULL, 'Q403', 'Agua de río', FALSE),
(NULL, 'Q403', 'Agua estancada', FALSE),
(NULL, 'Q403', 'Agua sin tratar', FALSE);

-- Q404
INSERT INTO Option_ VALUES
(NULL, 'Q404', 'Desechos, productos químicos y basura', TRUE),
(NULL, 'Q404', 'Aire puro', FALSE),
(NULL, 'Q404', 'Rayos solares', FALSE),
(NULL, 'Q404', 'Frutas y verduras', FALSE);

-- Q405
INSERT INTO Option_ VALUES
(NULL, 'Q405', 'Reserva subterránea de agua', TRUE),
(NULL, 'Q405', 'Río artificial', FALSE),
(NULL, 'Q405', 'Tanque de agua en casa', FALSE),
(NULL, 'Q405', 'Lago con peces', FALSE);

-- Q406
INSERT INTO Option_ VALUES
(NULL, 'Q406', 'Acceso a agua potable y desagüe', TRUE),
(NULL, 'Q406', 'Solo agua embotellada', FALSE),
(NULL, 'Q406', 'Tener plantas en casa', FALSE),
(NULL, 'Q406', 'Reutilizar botellas', FALSE);

-- Q407
INSERT INTO Option_ VALUES
(NULL, 'Q407', 'Lugar donde se limpia el agua antes de usarse', TRUE),
(NULL, 'Q407', 'Fábrica de bebidas', FALSE),
(NULL, 'Q407', 'Pozo natural', FALSE),
(NULL, 'Q407', 'Estanque de animales', FALSE);

-- Q408
INSERT INTO Option_ VALUES
(NULL, 'Q408', 'Previene enfermedades y mejora la calidad de vida', TRUE),
(NULL, 'Q408', 'Evita lluvias', FALSE),
(NULL, 'Q408', 'Causa contaminación', FALSE),
(NULL, 'Q408', 'Aumenta la sequía', FALSE);

-- Q409
INSERT INTO Option_ VALUES
(NULL, 'Q409', 'Evitar la deforestación y contaminar ríos', TRUE),
(NULL, 'Q409', 'Construir represas masivas', FALSE),
(NULL, 'Q409', 'Talar árboles en la zona', FALSE),
(NULL, 'Q409', 'Verter residuos en el agua', FALSE);

-- Q410
INSERT INTO Option_ VALUES
(NULL, 'Q410', 'Reduce la disponibilidad y afecta la salud', TRUE),
(NULL, 'Q410', 'Genera más agua potable', FALSE),
(NULL, 'Q410', 'Aumenta la biodiversidad', FALSE),
(NULL, 'Q410', 'Mejora la calidad de vida', FALSE);

-- Q411
INSERT INTO Option_ VALUES
(NULL, 'Q411', 'Falta de tratamiento y vertido de residuos', TRUE),
(NULL, 'Q411', 'La lluvia ácida es la única causa', FALSE),
(NULL, 'Q411', 'Solo ocurre en zonas desérticas', FALSE),
(NULL, 'Q411', 'La contaminación del aire no influye', FALSE);

-- Q412
INSERT INTO Option_ VALUES
(NULL, 'Q412', 'Usar dispositivos ahorradores y cerrar grifos', TRUE),
(NULL, 'Q412', 'Lavar autos a diario', FALSE),
(NULL, 'Q412', 'Usar mangueras en exceso', FALSE),
(NULL, 'Q412', 'No reparar fugas', FALSE);

-- Q413
INSERT INTO Option_ VALUES
(NULL, 'Q413', 'Debe garantizar acceso equitativo y sostenible', TRUE),
(NULL, 'Q413', 'No tiene responsabilidad alguna', FALSE),
(NULL, 'Q413', 'Solo debe cobrar tarifas', FALSE),
(NULL, 'Q413', 'Debe privatizar todo el servicio', FALSE);

-- Q414
INSERT INTO Option_ VALUES
(NULL, 'Q414', 'El acceso al agua reduce enfermedades', TRUE),
(NULL, 'Q414', 'El agua no tiene relación con la salud', FALSE),
(NULL, 'Q414', 'El agua potable causa alergias', FALSE),
(NULL, 'Q414', 'La salud solo depende de la comida', FALSE);

-- Q415
INSERT INTO Option_ VALUES
(NULL, 'Q415', 'El acceso al agua es esencial para una vida digna', TRUE),
(NULL, 'Q415', 'Es un bien de lujo', FALSE),
(NULL, 'Q415', 'Solo lo usan los agricultores', FALSE),
(NULL, 'Q415', 'Debe venderse sin regulación', FALSE);

-- TEMPLATE
INSERT INTO Template VALUES
('TP0001', 'Evaluación Escolar', 'Solo preguntas fáciles', 10, 0, 0),
('TP0002', 'Evaluación Universitaria', 'Intermedia y difícil', 0, 5, 5),
('TP0003', 'Evaluación Ciudadana', 'Mix básico e intermedio', 5, 5, 0);


INSERT INTO Achievement_lvl VALUES
('A1', 'Básico', 'Debajo del promedio'),
('A2', 'Avanzado', 'Buen desempeño'),
('A3', 'Excelente', 'Rendimiento sobresaliente'),
('A4', 'Perfecto', 'Sin errores');

INSERT INTO Feedback VALUES
('F001', 'Respuesta incorrecta, revisar conceptos'),
('F002', 'Respuesta clara y precisa'),
('F003', 'Demuestra conocimiento avanzado');

-- USUARIOS
INSERT INTO User_ VALUES
('U001', 'Ana Lucia', 'Ramirez', 'Torres', 'ana.lucia@correo.com', 'AnaLuR#2025', 'E1'),
('U002', 'Carlos Javier', 'Perez', 'Lopez', 'carlos.j@correo.com', 'CarloJ#2025', 'E2'),
('U003', 'Maria Elena', 'Garcia', 'Soto', 'maria.e@correo.com', 'MariEG#2025', 'E3'),
('U004', 'Luis Fernando', 'Martinez', 'Reyes', 'luis.f@correo.com', 'LuisFR#2025', 'E2'),
('U005', 'Paula Andrea', 'Diaz', 'Morales', 'paula.a@correo.com', 'PaulAD#2025', 'E1'),
('U006', 'Jose Manuel', 'Castillo', 'Rojas', 'jose.m@correo.com', 'JoseMR#2025', 'E1'),
('U007', 'Laura Isabel', 'Torres', 'Gomez', 'laura.i@correo.com', 'LaurIG#2025', 'E3'),
('U008', 'Diego Armando', 'Moreno', 'Chavez', 'diego.a@correo.com', 'DiegMC#2025', 'E2'),
('U009', 'Valeria Sofia', 'Ruiz', 'Mendoza', 'valeria.s@correo.com', 'ValeRM#2025', 'E1'),
('U010', 'Jorge Luis', 'Vargas', 'Silva', 'jorge.l@correo.com', 'JorgVS#2025', 'E2');


-- Asignar preguntas aleatorias a los exámenes

CALL generar_examen_aleatorio('U001', 'TP0001', @exam1);
CALL generar_examen_aleatorio('U002', 'TP0003', @exam2);
CALL generar_examen_aleatorio('U003', 'TP0002', @exam3);
CALL generar_examen_aleatorio('U004', 'TP0001', @exam4);
CALL generar_examen_aleatorio('U005', 'TP0002', @exam5);
CALL generar_examen_aleatorio('U006', 'TP0003', @exam6);
CALL generar_examen_aleatorio('U007', 'TP0001', @exam7);
CALL generar_examen_aleatorio('U008', 'TP0003', @exam8);
CALL generar_examen_aleatorio('U009', 'TP0002', @exam9);
CALL generar_examen_aleatorio('U010', 'TP0001', @exam10);

-- Simular respuestas para todos los exámenes generados
CALL simular_respuestas(@exam1);
CALL simular_respuestas(@exam2);
CALL simular_respuestas(@exam3);
CALL simular_respuestas(@exam4);
CALL simular_respuestas(@exam5);
CALL simular_respuestas(@exam6);
CALL simular_respuestas(@exam7);
CALL simular_respuestas(@exam8);
CALL simular_respuestas(@exam9);
CALL simular_respuestas(@exam10);

-- Calcular resultados
CALL calcular_resultado(@exam1);
CALL calcular_resultado(@exam2);
CALL calcular_resultado(@exam3);
CALL calcular_resultado(@exam4);
CALL calcular_resultado(@exam5);
CALL calcular_resultado(@exam6);
CALL calcular_resultado(@exam7);
CALL calcular_resultado(@exam8);
CALL calcular_resultado(@exam9);
CALL calcular_resultado(@exam10);

CREATE OR REPLACE VIEW vw_usuarios_aprobados AS
SELECT 
  u.id_user,
  CONCAT(u.full_name, ' ', u.last_name) AS nombre_completo,
  e.id_exam,
  e.application_date,
  e.attempt,
  r.total_score,
  r.percentage_correct,
  a.name_a AS nivel_logro
FROM Result r
JOIN Exam e ON r.fk_exam = e.id_exam
JOIN User_ u ON e.fk_user = u.id_user
JOIN Achievement_lvl a ON r.fk_achvlvl = a.id_achvlvl
WHERE r.percentage_correct >= 70
ORDER BY r.percentage_correct DESC;

SELECT * FROM vw_usuarios_aprobados;

-- VIEW USUARIOS DESAPROBADOS

CREATE OR REPLACE VIEW vw_usuarios_desaprobados AS
SELECT 
  u.id_user,
  CONCAT(u.full_name, ' ', u.last_name) AS nombre_completo,
  e.id_exam,
  e.application_date,
  e.attempt,
  r.total_score,
  r.percentage_correct,
  a.name_a AS nivel_logro
FROM Result r
JOIN Exam e ON r.fk_exam = e.id_exam
JOIN User_ u ON e.fk_user = u.id_user
JOIN Achievement_lvl a ON r.fk_achvlvl = a.id_achvlvl
WHERE r.percentage_correct < 70
ORDER BY r.percentage_correct ASC;

SELECT * FROM vw_usuarios_desaprobados;

-- VIEW Resumen General de Resultados por Usuario

CREATE OR REPLACE VIEW vw_resumen_usuario AS
SELECT 
  u.id_user,
  CONCAT(u.full_name, ' ', u.last_name) AS nombre_completo,
  COUNT(e.id_exam) AS total_examenes,
  AVG(r.total_score) AS promedio_score,
  AVG(r.percentage_correct) AS promedio_porcentaje,
  MAX(r.percentage_correct) AS max_porcentaje,
  MIN(r.percentage_correct) AS min_porcentaje
FROM User_ u
JOIN Exam e ON u.id_user = e.fk_user
JOIN Result r ON r.fk_exam = e.id_exam
GROUP BY u.id_user, u.full_name, u.last_name;

SELECT * FROM vw_resumen_usuario;

-- VIEW Detalle de Examenes por Tema

CREATE OR REPLACE VIEW vw_examen_temas AS
SELECT 
    e.id_exam,
    u.id_user,
    CONCAT(u.full_name, ' ', u.last_name) AS nombre_completo,
    t.template_name,
    tp.topic_name,
    COUNT(DISTINCT q.id_question) AS total_preguntas_tema
FROM Exam e
JOIN User_ u ON u.id_user = e.fk_user
JOIN Template t ON t.id_template = e.fk_template
JOIN Answer a ON a.fk_exam = e.id_exam
JOIN Question q ON q.id_question = a.fk_question
JOIN Question_Bank qb ON q.fk_questionbank = qb.id_questionbank
JOIN Topic tp ON qb.fk_topic = tp.id_topic
GROUP BY e.id_exam, u.id_user, u.full_name, u.last_name, t.template_name, tp.topic_name;

SELECT * FROM vw_examen_temas;

CREATE OR REPLACE VIEW vw_feedback_detallado AS
SELECT 
  a.id_answer,
  CONCAT(u.full_name, ' ', u.last_name) AS usuario,
  q.question_text AS pregunta,
  a.user_response AS respuesta_usuario,
  (SELECT option_text FROM Option_ WHERE fk_question = q.id_question AND is_correct = TRUE LIMIT 1) AS respuesta_correcta,
  f.comment AS retroalimentacion,
  a.partial_score AS puntaje_parcial,
  e.application_date AS fecha_examen
FROM Answer a
JOIN Exam e ON a.fk_exam = e.id_exam
JOIN User_ u ON e.fk_user = u.id_user
JOIN Question q ON a.fk_question = q.id_question
LEFT JOIN Feedback f ON a.fk_feedback = f.id_feedback
ORDER BY e.application_date DESC, u.last_name, u.full_name;

SELECT * FROM vw_feedback_detallado;

CREATE OR REPLACE VIEW vw_preguntas_opciones_correctas AS
SELECT 
  q.id_question,
  q.question_text,
  qb.qb_name AS banco_preguntas,
  tp.topic_name AS tema,
  dl.name_difficulty AS dificultad,
  el.name_educationlvl AS nivel_educativo,
  o.option_text AS respuesta_correcta
FROM Question q
JOIN Question_Bank qb ON q.fk_questionbank = qb.id_questionbank
JOIN Topic tp ON qb.fk_topic = tp.id_topic
JOIN Difficulty_Level dl ON q.fk_difficulty = dl.id_difficulty
JOIN Education_Level el ON q.fk_educationlevel = el.id_educationlevel
JOIN Option_ o ON q.id_question = o.fk_question AND o.is_correct = TRUE;

SELECT * FROM vw_preguntas_opciones_correctas;

CREATE OR REPLACE VIEW vw_resultado_por_nivel_educativo AS
SELECT 
  el.name_educationlvl AS nivel_educativo,
  COUNT(DISTINCT r.id_result) AS total_examenes,
  COUNT(DISTINCT u.id_user) AS total_usuarios,
  AVG(r.percentage_correct) AS promedio_porcentaje,
  MAX(r.percentage_correct) AS mejor_porcentaje,
  MIN(r.percentage_correct) AS peor_porcentaje
FROM Education_Level el
LEFT JOIN User_ u ON el.id_educationlevel = u.fk_educationlevel
LEFT JOIN Exam e ON u.id_user = e.fk_user
LEFT JOIN Result r ON e.id_exam = r.fk_exam
GROUP BY el.name_educationlvl
ORDER BY promedio_porcentaje DESC;

SELECT * FROM vw_resultado_por_nivel_educativo;

SELECT * from Answer;
Select * from Template;
SELECT * FROM Result;