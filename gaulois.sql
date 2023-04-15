-- 1. Nom des lieux qui finissent par 'um'.
SELECT *
FROM lieu
WHERE nom_lieu 
LIKE '%um'
---------------------------------------------------------------------------------

-- 2. Nombre de personnages par lieu (trié par nombre de personnages décroissant).
-- Version avec affichage des id des villages
SELECT id_lieu, COUNT(*)
FROM personnage
GROUP BY id_lieu
ORDER BY COUNT(*) DESC

--Version avec affichage des nom des villages
SELECT nom_lieu, COUNT(p.id_lieu) AS nbGaulois
FROM personnage p
INNER JOIN lieu l ON p.id_lieu = l.id_lieu
GROUP BY l.id_lieu
ORDER BY COUNT(*) DESC
---------------------------------------------------------------------------------

-- 3. Nom des personnages + spécialité + adresse et lieu d'habitation, triés par lieu puis par nom de personnage.

SELECT nom_personnage, nom_specialite, adresse_personnage, nom_lieu
FROM personnage
INNER JOIN lieu ON personnage.id_lieu = lieu.id_lieu
INNER JOIN specialite ON personnage.id_specialite = specialite.id_specialite
ORDER BY nom_lieu, nom_personnage
---------------------------------------------------------------------------------

-- 4. Nom des spécialités avec nombre de personnages par spécialité (trié par nombre de personnages décroissant).

SELECT nom_specialite, COUNT(personnage.id_specialite) AS nombre_personnage
FROM personnage
INNER JOIN specialite ON personnage.id_specialite = specialite.id_specialite
GROUP BY specialite.id_specialite
ORDER BY COUNT(*) DESC

---------------------------------------------------------------------------------

-- 5. Nom, date et lieu des batailles, classées de la plus récente à la plus ancienne (dates affichées au format jj/mm/aaaa).

SELECT nom_bataille, DATE_FORMAT(date_bataille, "%d/%m/%Y") AS date_bataille_fr, nom_lieu
FROM bataille
INNER JOIN lieu ON bataille.id_lieu = lieu.id_lieu
ORDER BY date_bataille DESC

---------------------------------------------------------------------------------

-- 6. Nom des potions + coût de réalisation de la potion (trié par coût décroissant).

SELECT po.nom_potion, SUM(i.cout_ingredient*co.qte) AS cout_realisation_potion
FROM potion po
INNER JOIN composer co ON po.id_potion = co.id_potion
INNER JOIN ingredient i ON co.id_ingredient = i.id_ingredient
GROUP BY po.id_potion
ORDER BY cout_realisation_potion DESC

---------------------------------------------------------------------------------

-- 7. Nom des ingrédients + coût + quantité de chaque ingrédient qui composent la potion 'Santé'.

SELECT i.nom_ingredient, i.cout_ingredient, co.qte
FROM ingredient i
INNER JOIN composer co ON i.id_ingredient = co.id_ingredient
INNER JOIN potion po ON co.id_potion = po.id_potion
WHERE po.nom_potion = "Santé"

---------------------------------------------------------------------------------

-- 8. Nom du ou des personnages qui ont pris le plus de casques dans la bataille 'Bataille du village gaulois'.
-- PISTES : 

-- Combien de casque au total chaque perso a t il recupérer
SELECT p_c.id_personnage, per.nom_personnage, SUM(p_c.qte) AS casque_pris
FROM prendre_casque p_c
INNER JOIN personnage per ON p_c.id_personnage = per.id_personnage
GROUP BY p_c.id_personnage
ORDER BY casque_pris DESC

-- combien de casque a été récupérer dans la bataille demandé
SELECT p_c.id_bataille, b.nom_bataille, SUM(p_c.qte) AS casque_pris
FROM prendre_casque p_c
INNER JOIN bataille b ON p_c.id_bataille = b.id_bataille
WHERE b.nom_bataille = "Bataille du village gaulois"
GROUP BY p_c.id_bataille

-- Possible solution, fonctionne mais long
SELECT per.id_personnage, per.nom_personnage
FROM personnage per
WHERE per.id_personnage IN (
	SELECT m.id_personnage
	FROM (
		SELECT maximum.id_personnage, maximum.nombre_casque_pris
		FROM (
			SELECT p_c.id_personnage, SUM(p_c.qte) AS nombre_casque_pris
			FROM prendre_casque p_c
			WHERE p_c.id_bataille IN (
				SELECT b.id_bataille
				FROM bataille b
				WHERE b.nom_bataille = "Bataille du village gaulois"
				)
			GROUP BY p_c.id_personnage
		) AS maximum
	) AS m
	WHERE m.nombre_casque_pris IN (
		SELECT MAX(m.nombre_casque_pris)
		FROM (
			SELECT maximum.id_personnage, maximum.nombre_casque_pris
			FROM (
				SELECT p_c.id_personnage, SUM(p_c.qte) AS nombre_casque_pris
				FROM prendre_casque p_c
				WHERE p_c.id_bataille IN (
					SELECT b.id_bataille
					FROM bataille b
					WHERE b.nom_bataille = "Bataille du village gaulois"
					)
				GROUP BY p_c.id_personnage
			) AS maximum
		) AS m
	)
)

-- Solution :
SELECT p.nom_personnage, SUM(pc.qte) AS nb_casques
FROM personnage p, bataille b, prendre_casque pc
WHERE p.id_personnage = pc.id_personnage
AND pc.id_bataille = b.id_bataille AND b.nom_bataille = "Bataille du village gaulois"
GROUP BY p.id_personnage
HAVING nb_casques >= ALL(
	SELECT SUM(pc.qte)
	FROM prendre_casque pc, bataille b
	WHERE b.id_bataille = pc.id_bataille
	AND b.nom_bataille = "Bataille du village gaulois"
	GROUP BY pc.id_personnage
)

---------------------------------------------------------------------------------

-- 9. Nom des personnages et leur quantité de potion bue (en les classant du plus grand buveur au plus petit).

SELECT per.id_personnage, per.nom_personnage, SUM(bo.dose_boire) AS quantite_bu
FROM personnage per
INNER JOIN boire bo ON per.id_personnage = bo.id_personnage
GROUP BY per.id_personnage
ORDER BY quantite_bu DESC

---------------------------------------------------------------------------------

-- 10. Nom de la bataille où le nombre de casques pris a été le plus important.
-- PISTES :
-- combien de casque a été récupérer dans chaque bataille
SELECT p_c.id_bataille, b.nom_bataille, SUM(p_c.qte) AS casque_pris
FROM prendre_casque p_c
INNER JOIN bataille b ON p_c.id_bataille = b.id_bataille
GROUP BY p_c.id_bataille
ORDER BY casque_pris DESC

-- TENTATIVE NON CONCLUANTE :
SELECT nom_bataille, MAX(c.casque_pris)
FROM (
	SELECT p_c.id_bataille, b.nom_bataille, SUM(p_c.qte) AS casque_pris
	FROM prendre_casque p_c
	INNER JOIN bataille b ON p_c.id_bataille = b.id_bataille
	GROUP BY p_c.id_bataille
) AS c
GROUP BY id_bataille

-- Solution :
SELECT b.id_bataille, b.nom_bataille, SUM(pc.qte) AS nombre_casque_pris
FROM bataille b, prendre_casque pc
WHERE b.id_bataille = pc.id_bataille
GROUP BY b.id_bataille
HAVING nombre_casque_pris >= ALL(
	SELECT SUM(pc.qte)
	FROM prendre_casque pc
	GROUP BY pc.id_bataille
)

---------------------------------------------------------------------------------

--11. Combien existe-t-il de casques de chaque type et quel est leur coût total ? (classés par nombre décroissant)

SELECT tc.id_type_casque, tc.nom_type_casque, COUNT(ca.id_type_casque) AS nombre_casque_type, SUM(ca.cout_casque) AS cout_total
FROM type_casque tc
INNER JOIN casque ca ON tc.id_type_casque = ca.id_type_casque
GROUP BY tc.id_type_casque
ORDER BY cout_total DESC

---------------------------------------------------------------------------------

-- 12. Nom des potions dont un des ingrédients est le poisson frais.

SELECT po.nom_potion
FROM potion po
INNER JOIN composer co ON po.id_potion = co.id_potion
INNER JOIN ingredient i ON co.id_ingredient = i.id_ingredient
WHERE i.nom_ingredient = "Poisson frais"

---------------------------------------------------------------------------------

-- 13. Nom du / des lieu(x) possédant le plus d'habitants, en dehors du village gaulois.

SELECT l.id_lieu, l.nom_lieu, COUNT(p.id_lieu) AS habitant
FROM lieu l, personnage p
WHERE l.nom_lieu != "Village gaulois" AND l.id_lieu = p.id_lieu
GROUP BY l.id_lieu
HAVING habitant >= ALL(
	SELECT COUNT(p.id_lieu)
	FROM personnage p, lieu l
	WHERE l.nom_lieu != "Village gaulois" AND l.id_lieu = p.id_lieu
	GROUP BY p.id_lieu
)

---------------------------------------------------------------------------------

-- 14. Nom des personnages qui n'ont jamais bu aucune potion.

-- Version sans requête
SELECT per.id_personnage, per.nom_personnage
FROM personnage per
LEFT JOIN boire bo ON per.id_personnage = bo.id_personnage
WHERE bo.id_personnage IS NULL

-- Version avec une sous requête
SELECT per.id_personnage, per.nom_personnage
FROM personnage per
WHERE per.id_personnage NOT IN (
	SELECT bo.id_personnage
	FROM boire bo
)

---------------------------------------------------------------------------------

-- 15. Nom du / des personnages qui n'ont pas le droit de boire de la potion 'Magique'.

-- Version avec verification de l'id de la potion
SELECT per.id_personnage, per.nom_personnage
FROM personnage per
WHERE per.id_personnage NOT IN (
	SELECT a_b.id_personnage
	FROM autoriser_boire a_b
	WHERE a_b.id_potion = 1
)

-- Version avec verification du nom de la potion
SELECT per.id_personnage, per.nom_personnage
FROM personnage per
WHERE per.id_personnage NOT IN (
	SELECT a_b.id_personnage
	FROM autoriser_boire a_b
	WHERE a_b.id_potion IN (
		SELECT potion.id_potion
		FROM potion
		WHERE potion.nom_potion = "Magique"
	)
)

------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- A. Ajoutez le personnage suivant : Champdeblix, agriculteur résidant à la ferme Hantassion de Rotomagus.

INSERT INTO personnage (nom_personnage, adresse_personnage, id_lieu, id_specialite)
VALUES ("Champdeblix",
			"Ferme Hantassion",
			(SELECT l.id_lieu
			FROM lieu l
			WHERE l.nom_lieu = "Rotomagus"),
			(SELECT s.id_specialite
			FROM specialite s
			WHERE s.nom_specialite = "Agriculteur")
)

---------------------------------------------------------------------------------

-- B. Autorisez Bonemine à boire de la potion magique, elle est jalouse d'Iélosubmarine...

INSERT INTO autoriser_boire (id_potion, id_personnage)
VALUES (
	(SELECT po.id_potion
	FROM potion po
	WHERE po.nom_potion = "Magique")
	,
	(SELECT p.id_personnage
	FROM personnage p
	WHERE p.nom_personnage = "Bonemine")
)

---------------------------------------------------------------------------------

-- C. Supprimez les casques grecs qui n'ont jamais été pris lors d'une bataille.

DELETE FROM casque
WHERE id_casque IN (
	SELECT * 
	FROM (
		SELECT ca.id_casque
		FROM casque ca, type_casque tc
		WHERE ca.id_casque NOT IN (
			SELECT ca.id_casque
			FROM casque ca, prendre_casque pc, type_casque tc
			WHERE ca.id_casque = pc.id_casque
			AND ca.id_type_casque = tc.id_type_casque
			AND tc.nom_type_casque = "Grec"
			GROUP BY ca.id_casque
		)
		AND ca.id_type_casque = tc.id_type_casque
		AND tc.nom_type_casque = "Grec"
	) AS c
)

---------------------------------------------------------------------------------

-- D. Modifiez l'adresse de Zérozérosix : il a été mis en prison à Condate.
UPDATE personnage
SET adresse_personnage = "Prison",
	id_lieu = (
	SELECT l.id_lieu
	FROM lieu l
	WHERE l.nom_lieu = "Condate"
	)
WHERE id_personnage IN (
	SELECT *
	FROM (
		SELECT per.id_personnage
		FROM personnage per
		WHERE per.nom_personnage = "Zérozérosix"
	) AS p
)

-- Corrigé 
UPDATE personnage
SET adresse_personnage = "Prison",
	id_lieu = (
	SELECT l.id_lieu
	FROM lieu l
	WHERE l.nom_lieu = "Condate"
	)
WHERE nom_personnage = "Zérozérosix"

---------------------------------------------------------------------------------

-- E. La potion 'Soupe' ne doit plus contenir de persil.
DELETE FROM composer
WHERE id_potion IN (
	SELECT *
	FROM (
		SELECT co.id_potion
		FROM composer co
		WHERE co.id_potion IN (
			SELECT po.id_potion
			FROM potion po
			WHERE po.nom_potion = "Soupe"
		)
	) AS p
)
AND id_ingredient IN (
	SELECT i.id_ingredient
	FROM ingredient i
	WHERE i.nom_ingredient = "Persil"
)

---------------------------------------------------------------------------------

-- F. Obélix s'est trompé : ce sont 42 casques Weisenau, et non Ostrogoths, qu'il a pris lors de la bataille 'Attaque de la banque postale'. Corrigez son erreur !

UPDATE prendre_casque
SET id_casque = (
	SELECT ca.id_casque
	FROM casque ca
	WHERE ca.nom_casque = "Weisenau"),
	qte = 42
WHERE id_bataille IN (
	SELECT *
	FROM (
		SELECT pc.id_bataille
		FROM prendre_casque pc
		WHERE pc.id_bataille IN (
			SELECT ba.id_bataille
			FROM bataille ba
			WHERE ba.nom_bataille = "Attaque de la banque postale"
		)
	) AS c	
)
AND id_personnage IN (
	SELECT per.id_personnage
	FROM personnage per
	WHERE per.nom_personnage = "Obélix"
)
AND id_casque IN (
	SELECT ca.id_casque
	FROM casque ca
	WHERE ca.nom_casque = "Ostrogoth"
)

---------------------------------------------------------------------------------