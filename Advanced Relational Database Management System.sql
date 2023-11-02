DROP TABLE ensemblecontientattribut PURGE;

DROP TABLE ensemblesattributs PURGE;

DROP TABLE DFs  purge;
drop sequence NumDF;
DROP FUNCTION creerensattvide;

DROP SEQUENCE numensatt;

DROP FUNCTION ajouteratt;

DROP FUNCTION creerensatt;

DROP FUNCTION ensatt2chaine;

DROP FUNCTION estelement;

DROP FUNCTION estegal;

DROP FUNCTION estinclus;

DROP FUNCTION unionatt;

DROP FUNCTION soustractionatt;

DROP FUNCTION copieatt;

DROP FUNCTION intersectionatt;

CREATE TABLE ensemblesattributs (
    numensatt NUMBER(5)
        CONSTRAINT pk_ensat PRIMARY KEY
);

CREATE TABLE ensemblecontientattribut (
    numensatt  NUMBER(5),
    nomatt     VARCHAR2(15),
    CONSTRAINT fk_ensat FOREIGN KEY ( numensatt )
        REFERENCES ensemblesattributs ( numensatt )
            ON DELETE CASCADE,
    CONSTRAINT pk_enscat PRIMARY KEY ( numensatt,
                                       nomatt )
);

CREATE SEQUENCE numensatt;

CREATE OR REPLACE FUNCTION creerensattvide RETURN NUMBER IS
    num NUMBER;
BEGIN
    INSERT INTO ensemblesattributs VALUES ( numensatt.NEXTVAL ) RETURNING numensatt INTO num;

    RETURN num;
END;
/

VARIABLE num1 NUMBER;

BEGIN
    :num1 := creerensattvide;
END;
/

PRINT num1;

CREATE OR REPLACE PROCEDURE ajouteratt (
    p_nomatt     VARCHAR,
    p_numensatt  NUMBER
) IS
BEGIN
    INSERT INTO ensemblecontientattribut VALUES (
        p_numensatt,
        p_nomatt
    );

END;
/

EXECUTE ajouteratt('A', 1);
/

CREATE OR REPLACE FUNCTION creerensatt (
    p_chaineatt VARCHAR
) RETURN NUMBER IS
    num   NUMBER;
    atts  VARCHAR2(2000);
    pos   INT;
BEGIN
  -- Traiter le cas où la chaîne est vide
    IF p_chaineatt IS NULL THEN
        RETURN NULL;
    END IF;
    num := creerensattvide;
    atts := trim(p_chaineatt);
  
  -- Traiter le cas où il n'y a qu'un seul attribut sans virgule
    IF instr(atts, ',') = 0 THEN
        ajouteratt(atts, num);
        RETURN num;
    END IF;
  
  -- Traiter le cas où il y a plusieurs attributs séparés par des virgules
    WHILE atts IS NOT NULL LOOP
        pos := instr(atts, ',');
        IF pos = 0 THEN
            ajouteratt(atts, num);
            RETURN num;
        ELSE
            ajouteratt(substr(atts, 1, pos - 1), num);
            atts := substr(atts, pos + 1);
        END IF;

    END LOOP;

END;
/

VARIABLE num NUMBER;

BEGIN
    :num2 := creerensatt('A,B,C');
END;
/

PRINT num2;

SELECT
    *
FROM
    ensemblecontientattribut
WHERE
    numensatt = :num2;

ROLLBACK;

VARIABLE num3 NUMBER;

BEGIN
    :num3 := creerensatt('E,F,G');
END;
/

PRINT num3;

SELECT
    *
FROM
    ensemblesattributs;

SELECT
    *
FROM
    ensemblecontientattribut;

CREATE OR REPLACE FUNCTION ensatt2chaine (
    p_numensatt NUMBER
) RETURN VARCHAR IS
    atts VARCHAR2(2000);
BEGIN
    SELECT
        LISTAGG(nomatt, ',') WITHIN GROUP(
            ORDER BY
                nomatt
        )
    INTO atts
    FROM
        ensemblecontientattribut
    WHERE
        numensatt = p_numensatt;

    RETURN atts;
END;
/

SELECT
    ensatt2chaine(:num3)
FROM
    dual;

-- Définition de la fonction EstElement
CREATE OR REPLACE FUNCTION estelement (
    p_nomatt     VARCHAR,
    p_numensatt  NUMBER
) RETURN INTEGER AS
  -- Déclaration de la variable result qui contiendra le résultat de la fonction
    result INTEGER;
BEGIN
  -- Vérification si l'attribut est contenu dans l'ensemble
    SELECT
        COUNT(*)
    INTO result
    FROM
        ensemblecontientattribut
    WHERE
            numensatt = p_numensatt
        AND nomatt = p_nomatt;
  
  -- Si result est supérieur à 0, l'attribut est contenu dans l'ensemble
  -- Sinon il n'est pas contenu dans l'ensemble
    IF result > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/

SELECT
    estelement('A', 3)
FROM
    dual;
    
    
    
    -- Définition de la fonction EstInclus
CREATE OR REPLACE FUNCTION estinclus (
    p_numensatt_1  NUMBER,
    p_numensatt_2  NUMBER
) RETURN INTEGER AS
  -- Déclaration de la variable result qui contiendra le résultat de la fonction
    result INTEGER;
BEGIN
  -- Vérification si le premier ensemble est inclus dans le second
    SELECT
        COUNT(*)
    INTO result
    FROM
        ensemblecontientattribut
    WHERE
            numensatt = p_numensatt_1
        AND nomatt IN (
            SELECT
                nomatt
            FROM
                ensemblecontientattribut
            WHERE
                numensatt = p_numensatt_2
        );
  
  -- Si result est supérieur à 0, le premier ensemble est inclus dans le second
  -- Sinon il n'est pas inclus dans le second
    IF result > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/

VARIABLE num4 NUMBER;

BEGIN
    :num4 := creerensatt('E,F,G,H');
END;
/

SELECT
    *
FROM
    ensemblecontientattribut;

-- Vérification si l'ensemble de numéro N est inclus dans l'ensemble de numéro M
SELECT
    estinclus(:num3, :num4) AS num_3_estinclu_dans_4
FROM
    dual;

-- Définition de la fonction EstEgal
CREATE OR REPLACE FUNCTION estegal (
    p_numensatt_1  NUMBER,
    p_numensatt_2  NUMBER
) RETURN INTEGER AS
  -- Déclaration de la variable result qui contiendra le résultat de la fonction
    result INTEGER;
BEGIN
  -- Vérification si le premier ensemble est égal au second
    SELECT
        COUNT(*)
    INTO result
    FROM
        ensemblecontientattribut
    WHERE
            numensatt = p_numensatt_1
        AND nomatt IN (
            SELECT
                nomatt
            FROM
                ensemblecontientattribut
            WHERE
                numensatt = p_numensatt_2
        )
        AND nomatt NOT IN (
            SELECT
                nomatt
            FROM
                ensemblecontientattribut
            WHERE
                    numensatt = p_numensatt_2
                AND nomatt NOT IN (
                    SELECT
                        nomatt
                    FROM
                        ensemblecontientattribut
                    WHERE
                        numensatt = p_numensatt_1
                )
        );
  
  -- Si result est supérieur à 0, le premier ensemble est égal au second
  -- Sinon il n'est pas égal au second
    IF result > 0 THEN
        RETURN 1;
    ELSE
        RETURN 0;
    END IF;
END;
/

SELECT
    estegal(1, 4)
FROM
    dual;

CREATE FUNCTION unionatt (
    p_numensatt1  NUMBER,
    p_numensatt2  NUMBER
) RETURN NUMBER IS
    v_numensatt  NUMBER;
    v_nomatt     VARCHAR(2000);
BEGIN
  -- Créer un nouvel ensemble vide avec un numéro généré par la séquence NumEnsAtt
    INSERT INTO ensemblesattributs VALUES ( numensatt.NEXTVAL ) RETURNING numensatt INTO v_numensatt;

  -- Récupérer les attributs des deux ensembles passés en argument, les combiner en un seul résultat
  -- et les insérer dans le nouvel ensemble
    INSERT INTO ensemblecontientattribut (
        numensatt,
        nomatt
    )
        SELECT
            v_numensatt,
            nomatt
        FROM
            ensemblecontientattribut
        WHERE
            numensatt = p_numensatt1
        UNION
        SELECT
            v_numensatt,
            nomatt
        FROM
            ensemblecontientattribut
        WHERE
            numensatt = p_numensatt2;

  -- Retourner le numéro du nouvel ensemble
    RETURN v_numensatt;
END;
/

VARIABLE num5 NUMBER

BEGIN
    :num5 := unionatt(3, 4);
END;
/

SELECT
    ensatt2chaine(:num5)
FROM
    dual;

-- Définition de la fonction IntersectionAtt
CREATE OR REPLACE FUNCTION intersectionatt (
    p_numensatt1  NUMBER,
    p_numensatt2  NUMBER
) RETURN NUMBER AS
  -- Déclaration des variables locales
  -- v_NumEnsAtt : variable utilisée pour stocker le numéro du nouvel ensemble créé
  -- v_NomAtt : variable utilisée pour stocker le nom de l'attribut courant
    v_numensatt  NUMBER;
    v_nomatt     VARCHAR(2000);
BEGIN
  -- Création du nouvel ensemble vide avec un numéro généré par la séquence NumEnsAtt
    INSERT INTO ensemblesattributs VALUES ( numensatt.NEXTVAL ) RETURNING numensatt INTO v_numensatt;

  -- Récupération des attributs des deux ensembles passés en argument, les combiner en un seul résultat
  -- et les insérer dans le nouvel ensemble
    INSERT INTO ensemblecontientattribut (
        numensatt,
        nomatt
    )
        SELECT
            v_numensatt,
            nomatt
        FROM
            ensemblecontientattribut
        WHERE
                numensatt = p_numensatt1
            AND nomatt IN (
                SELECT
                    nomatt
                FROM
                    ensemblecontientattribut
                WHERE
                    numensatt = p_numensatt2
            );

  -- Retourner le numéro du nouvel ensemble
    RETURN v_numensatt;
END;
/

VARIABLE num6 NUMBER

BEGIN
    :num6 := intersectionatt(3, 4);
END;
/

SELECT
    ensatt2chaine(:num6)
FROM
    dual;

-- Définition de la fonction CopieAtt
CREATE OR REPLACE FUNCTION copieatt (
    p_numensatt NUMBER
) RETURN NUMBER AS
  -- Déclaration des variables locales
  -- v_NumEnsAtt : variable utilisée pour stocker le numéro du nouvel ensemble créé
    v_numensatt NUMBER;
BEGIN
  -- Création du nouvel ensemble vide avec un numéro généré par la séquence NumEnsAtt
    INSERT INTO ensemblesattributs VALUES ( numensatt.NEXTVAL ) RETURNING numensatt INTO v_numensatt;

  -- Récupération des attributs de l'ensemble passé en argument, et les insérer dans le nouvel ensemble
    INSERT INTO ensemblecontientattribut (
        numensatt,
        nomatt
    )
        SELECT
            v_numensatt,
            nomatt
        FROM
            ensemblecontientattribut
        WHERE
            numensatt = p_numensatt;

  -- Retourner le numéro du nouvel ensemble
    RETURN v_numensatt;
END;
/

VARIABLE num7 NUMBER

BEGIN
    :num7 := copieatt(1);
END;
/

SELECT
    ensatt2chaine(:num7)
FROM
    dual;
    
    -- Définition de la fonction SoustractionAtt
CREATE OR REPLACE FUNCTION soustractionatt (
    p_numensatt1  NUMBER,
    p_numensatt2  NUMBER
) RETURN NUMBER AS
  -- Déclaration des variables locales
  -- v_NumEnsAtt : variable utilisée pour stocker le numéro du nouvel ensemble créé
  -- v_NomAtt : variable utilisée pour stocker le nom de l'attribut courant
    v_numensatt  NUMBER;
    v_nomatt     VARCHAR(2000);
BEGIN
  -- Création du nouvel ensemble vide avec un numéro généré par la séquence NumEnsAtt

    v_numensatt := creerensattvide;

  -- Récupération des attributs de l'ensemble passé en premier argument, et les insérer dans le nouvel ensemble
  -- en excluant les attributs de l'ensemble passé en second argument
    INSERT INTO ensemblecontientattribut (
        numensatt,
        nomatt
    )
        SELECT
            v_numensatt,
            nomatt
        FROM
            ensemblecontientattribut
        WHERE
                numensatt = p_numensatt1
            AND nomatt not in  (
                SELECT
                    nomatt
                FROM
                    ensemblecontientattribut
                WHERE
                        numensatt = p_numensatt2
            );

  -- Retourner le numéro du nouvel ensemble
    RETURN v_numensatt;
END;
/

VARIABLE num8 NUMBER

BEGIN
    :num8 := soustractionatt(4, 3);
END;
/

PRINT num8;

SELECT
    ensatt2chaine(:num8)
FROM
    dual;

SELECT
    *
FROM
    ensemblecontientattribut;
    
   CREATE TABLE DFs (
  NumDF NUMBER NOT NULL PRIMARY KEY,
  NumEnsGauche NUMBER NOT NULL,
  NumEnsDroit NUMBER NOT NULL,
  UNIQUE (NumEnsGauche, NumEnsDroit),
  FOREIGN KEY (NumEnsGauche) REFERENCES EnsemblesAttributs (NumEnsAtt),
  FOREIGN KEY (NumEnsDroit) REFERENCES EnsemblesAttributs (NumEnsAtt)
);

CREATE SEQUENCE NumDF;
 
    
    
    
