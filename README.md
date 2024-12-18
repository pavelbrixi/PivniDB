

# PivniDB
Semestrální projekt na předmět [Relační databázové systémy](https://portal.ujep.cz/portal/studium/prohlizeni.html?pc_pagenavigationalstate=AAAAAQAGMjMzOTM3EwEAAAABAAhzdGF0ZUtleQAAAAEAFC05MjIzMzcyMDM2ODU0NzcwMjI3AAAAAA**#prohlizeniSearchResult)

Cílem této semestrální práce bylo vytvořit databázi o libovolném tématu, pochopit problematiku a splnit požadavky obsažené v následujícím dokumentu:

[RDBS_Pozadavky-zapocet-2024.pdf](https://github.com/pavelbrixi/PivniDB/blob/main/RDBS_Pozadavky-zapocet-2024.pdf)

Moje databáze řeší problematiku skladového hospodářství velké skupiny pivovarů. Ve své práci jsem se zaměřil na hlídání stavu surovin ve skladu, kdo k datům má přístup a kdo, kdy a jak se surovinami nakládal. 

# ERD

<img src="https://github.com/pavelbrixi/PivniDB/blob/main/ERD_brixi_v3.pgerd.png">   

# Příkazy

## SELECT
- SELECT který vypočte průměrný počet záznamů na jednu tabulku v DB
```sql
SELECT AVG(pocet_zaznamu) AS prumerny_pocet
FROM (
    SELECT COUNT(*) AS pocet_zaznamu FROM Pivovary
    UNION ALL
    SELECT COUNT(*) FROM Typy
    UNION ALL
    SELECT COUNT(*) FROM Piva
    UNION ALL
    SELECT COUNT(*) FROM Ziviny
    UNION ALL
    SELECT COUNT(*) FROM Nutricni_hodnoty
    UNION ALL
    SELECT COUNT(*) FROM Uzivatele
    UNION ALL
    SELECT COUNT(*) FROM Recenze
    UNION ALL
    SELECT COUNT(*) FROM Udalosti
    UNION ALL
    SELECT COUNT(*) FROM Audit_log
    UNION ALL 
    SELECT COUNT(*) FROM Zamestnanci
    UNION ALL
    SELECT COUNT(*) FROM Sklad
    UNION ALL
    SELECT COUNT(*) FROM Sklad_log
) AS soucty_tabulky;
```
- SELECT s vnořeným SELECTEM  který najde piva s obsahem alkoholu vyšším než je průměr všech piv
```sql
SELECT Nazev 
FROM Piva 
WHERE ABV > (SELECT AVG(ABV) FROM Piva);
```
- SELECT s analytickou funkcí COUNT a agregační klauzulí GROUP BY který zobrazí počet piv pro každý pivovar
```sql
SELECT (SELECT Nazev FROM Pivovary WHERE Pivovary.PivovarID = p.PivovarID) 
AS Nazev_pivovaru, COUNT(*) AS pocet_piv
FROM Piva p
GROUP BY p.PivovarID
ORDER BY pocet_piv DESC;
```
- SELECT řešící hierarchii zobrazí všechny zaměstnance (+ pozici) a jejich nadřízené (+ jejich pozici)
```sql
SELECT 
z.Jmeno_a_prijmeni AS "Jméno a příjmení",
z.Pozice AS "Pozice pracovníka",
p.Nazev AS "Název pivovaru",
nz.Jmeno_a_prijmeni AS "Nadřízený",
nz.Pozice AS "Pozice nadřízeného"
FROM Zamestnanci z
LEFT JOIN Pivovary p ON z.PivovarID = p.PivovarID
LEFT JOIN Zamestnanci nz ON z.Nadrizena_osoba = nz.ZamestnanecID;
```

## VIEW
- View s podstatnými informacemi z několika tabulek najednou (Piva, Pivovary, Recenze). Zobrazí všechna piva z tabulky Piva, ke každému pivu zobrazí k němu příslušný pivovar (INNER JOIN) a poté se k záznamům připojí průměrné hodnocení a počet recenzí z tabulky Recenze (LEFT JOIN)
```sql
CREATE VIEW Prehled_piv AS
SELECT 
    P.Nazev AS Nazev_piva,
    PV.Nazev AS Nazev_pivovaru,
    AVG(R.Hodnoceni) AS Prumerne_hodnoceni,
    COUNT(R.RecenzeID) AS Pocet_recenzi
FROM Piva P
INNER JOIN Pivovary PV ON P.PivovarID = PV.PivovarID
LEFT JOIN Recenze R ON P.PivoID = R.PivoID
GROUP BY P.Nazev, PV.Nazev;

SELECT * FROM prehled_piv
```
- Příkaz pro zobrazení view
```sql
SELECT * FROM prehled_piv
```

## INDEX
- vytvoří INDEX který se bude starat aby v tabulce uživatelé byly unikátní emaily
```sql
CREATE UNIQUE INDEX idx_uzivatele_email ON Uzivatele(Email);
```
- ověření toho že když se uživatel pokusí vytvořit nový účet s emailem který již v databázi je -> databáze to nedovolí
```sql
INSERT INTO Uzivatele VALUES (
	40,
	'jannovak24',
	'jan.novak@example.com'
);
```

## FUNCTION
- funkce která vrátí průměr z hodnocení všech piv konkrétního pivovaru
```sql
CREATE OR REPLACE FUNCTION PrumerneHodnoceniPivovaru(pivovar_id INT)
RETURNS NUMERIC AS $$
DECLARE
    prumer NUMERIC;
BEGIN
    SELECT COALESCE (AVG(R.Hodnoceni), 0) INTO prumer
    FROM Recenze R
    JOIN Piva P ON R.PivoID = P.PivoID
    WHERE P.PivovarID = pivovar_id;
    RETURN prumer;
END;
$$ LANGUAGE plpgsql;
```
- příklad použití funkce
```sql
SELECT PrumerneHodnoceniPivovaru(1);
```
- funkce která vrátí tabulku piv splňující kritérium obsahu alkoholu 
```sql
CREATE OR REPLACE FUNCTION PivaVDanemRozmeziABV(spodni_mez NUMERIC, horni_mez NUMERIC)
RETURNS TABLE(Nazev VARCHAR, ABV NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT Piva.Nazev, Piva.ABV
    FROM Piva
    WHERE Piva.ABV BETWEEN spodni_mez AND horni_mez
    ORDER BY Piva.ABV;
END;
$$ LANGUAGE plpgsql;
```
- příklad použití funkce
```sql
SELECT * FROM PivaVDanemRozmeziABV(4.0, 8.0);
```

## PROCEDURE
- procedura která (pomocí NOTICE) vypíše všechna piva v databázi s podrobnými informacemi
```sql
CREATE OR REPLACE PROCEDURE zobraz_piva()
LANGUAGE plpgsql
AS $$
DECLARE
    pivo RECORD;
BEGIN
    FOR pivo IN SELECT nazev, abv, ibu FROM Piva
    LOOP
        RAISE NOTICE 'Pivo: %, ABV: %, IBU: %', pivo.nazev, pivo.abv, pivo.ibu;
    END LOOP;
END;
$$;
```
- zavolání procedury
```sql
CALL zobraz_piva();
```

## TRIGGER
- trigger který automaticky zapisuje úpravy názvů piv do tabulky audit_log
```sql
CREATE OR REPLACE FUNCTION AuditPivaUpdate()
RETURNS TRIGGER AS $$
BEGIN
    -- Pokud došlo ke změně názvu piva
    IF OLD.Nazev IS DISTINCT FROM NEW.Nazev THEN
        INSERT INTO Audit_log (Tabulka, Akce, PivoID, Predchozi_hodnota, Nova_hodnota, Uživatel)
        VALUES (
            'Piva', 
            'UPDATE', 
            OLD.PivoID, 
            OLD.Nazev, 
            NEW.Nazev, 
            CURRENT_USER
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
- samotný trigger
```sql
CREATE TRIGGER Trg_AuditPivaUpdate
AFTER UPDATE ON Piva
FOR EACH ROW
EXECUTE FUNCTION AuditPivaUpdate();
```
- test změny názvu
```sql
UPDATE Piva
SET Nazev = 'Plzeň'
WHERE PivoID = 1;
```
- změna názvu zpět
```sql
UPDATE Piva
SET Nazev = 'Pilsner Urquell'
WHERE PivoID = 1;
```
- náhled do tabulky audit_log
```sql
SELECT * FROM Audit_log
ORDER BY datum_cas DESC;
```

## TRANSACTION + LOCK
- následující transakce převede 5000 litrů vody ze skladu pivovaru 1 do skladu pivovaru 2.
- Během transakce se tabulka zamkne a až do skončení transakce si ostatní uživatele mohou tabulku pouze zobrazit (EXCLUSIVE MODE)
- Když se transakce neprovede (například z důvodu nedostatku suroviny ve skladu 1) tak se záznamy vrátí do původní podoby (ROLLBACK)
```sql
DO $$
BEGIN
    -- ZAMKNUTÍ TABULKY SKLAD PRO VŠECHNY OSTATNÍ UŽIVATELE
    LOCK TABLE Sklad IN EXCLUSIVE MODE;

    -- OVĚŘENÍ DOSTATKU SUROVINY VE SKLADU ODESÍLATELE
    IF (SELECT Mnozstvi FROM Sklad WHERE Surovina = 'Voda' AND PivovarID = 1) < 5000 THEN
        RAISE EXCEPTION 'Nedostatek vody ve skladu pivovaru 1';
    END IF;

    -- ODEČTENÍ MNOŽSTVÍ ZE SKLADU ODESÍLATELE
    UPDATE Sklad
    SET Mnozstvi = Mnozstvi - 5000
    WHERE Surovina = 'Voda' AND PivovarID = 1;

    -- PŘIČTENÍ ZDANÉHO MNOŽSTVÍ DO SKLADU PŘÍJEMCE
    -- pokud surovina ve skladu nemá žádný záznam tak se vytvoří
    INSERT INTO Sklad (Surovina, Mnozstvi, PivovarID, Jednotka)
    VALUES ('Voda', 5000, 2, 'litr') -- přidání hodnoty pro jednotku
    ON CONFLICT (Surovina, PivovarID)
    DO UPDATE SET Mnozstvi = Sklad.Mnozstvi + 5000;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
$$;
```

## USER
- vytvoření zaměstnance (CREATE USER)
- vytvoření role (CREATE ROLE)
- vytvoření politiky (CREATE POLICY)
- následné přidání role manager (GRANT)
```sql
CREATE USER "jnovak" WITH PASSWORD 'heslo123';

GRANT SELECT ON Sklad TO jnovak;

CREATE ROLE manager_1;

GRANT SELECT ON Sklad TO manager_1;

ALTER TABLE Sklad ENABLE ROW LEVEL SECURITY;

CREATE POLICY manager_1_sklad
    ON Sklad
    FOR SELECT
    TO manager_1
    USING (PivovarID = 1);

GRANT manager_1 TO "jnovak";
```
- vytvoření vedoucího skladu
```sql
CREATE USER skladadmin WITH PASSWORD 'sklad123';

-- Povolení uživateli skladadmin zobrazovat, vkládat a 
-- upravovat záznamy v tabulkách sklad a sklad_log
GRANT SELECT, INSERT, UPDATE ON TABLE sklad TO skladadmin;
GRANT SELECT, INSERT, UPDATE ON TABLE sklad_log TO skladadmin;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE sklad_skladid_seq TO skladadmin;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE sklad_log_logid_seq TO skladadmin;

CREATE ROLE warehouse_manager;

CREATE POLICY warehouse_manager_sklad
ON Sklad
FOR ALL
TO warehouse_manager
USING (true);

CREATE POLICY warehouse_manager_sklad_log
ON Sklad_log
FOR ALL
TO warehouse_manager
USING (true);

GRANT warehouse_manager TO skladadmin;
```

## Poznámky
- úprava množství suroviny v určitém skladu
```sql
UPDATE Sklad 
SET Mnozstvi = 9000.00 
WHERE Surovina = 'Voda' AND PivovarID = 1;
```
