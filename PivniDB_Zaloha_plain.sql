--
-- PostgreSQL database dump
--

-- Dumped from database version 16.3
-- Dumped by pg_dump version 16.3

-- Started on 2025-01-02 07:27:34

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 246 (class 1255 OID 41773)
-- Name: auditpivaupdate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.auditpivaupdate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


ALTER FUNCTION public.auditpivaupdate() OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 41824)
-- Name: logskladchanges(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.logskladchanges() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Při vkládání nového záznamu
    IF TG_OP = 'INSERT' THEN
        INSERT INTO Sklad_log (Akce, Surovina, SkladID, Puvodni_mnozstvi, Nove_mnozstvi)
        VALUES ('INSERT', NEW.Surovina, NEW.SkladID, NULL, NEW.Mnozstvi);
    
    -- Při aktualizaci záznamu
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO Sklad_log (Akce, Surovina, SkladID, Puvodni_mnozstvi, Nove_mnozstvi)
        VALUES ('UPDATE', OLD.Surovina, OLD.SkladID, OLD.Mnozstvi, NEW.Mnozstvi);
    
    -- Při smazání záznamu
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO Sklad_log (Akce, Surovina, SkladID, Puvodni_mnozstvi, Nove_mnozstvi)
        VALUES ('DELETE', OLD.Surovina, OLD.SkladID, OLD.Mnozstvi, NULL);
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.logskladchanges() OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 41739)
-- Name: pivavdanemrozmeziabv(numeric, numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pivavdanemrozmeziabv(spodni_mez numeric, horni_mez numeric) RETURNS TABLE(nazev character varying, abv numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT Piva.Nazev, Piva.ABV
    FROM Piva
    WHERE Piva.ABV BETWEEN spodni_mez AND horni_mez
    ORDER BY Piva.ABV;
END;
$$;


ALTER FUNCTION public.pivavdanemrozmeziabv(spodni_mez numeric, horni_mez numeric) OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 41737)
-- Name: pocetsilnychpiv(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.pocetsilnychpiv() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    pocet INT;
BEGIN
    SELECT COUNT(*) INTO pocet
    FROM Piva
    WHERE ABV > 5.0;
    RETURN pocet;
END;
$$;


ALTER FUNCTION public.pocetsilnychpiv() OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 41727)
-- Name: prumerna_hodnota_abv(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prumerna_hodnota_abv() RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    prumer_abv NUMERIC;
BEGIN
    SELECT AVG(abv) INTO prumer_abv FROM Piva;
    RETURN prumer_abv;
END;
$$;


ALTER FUNCTION public.prumerna_hodnota_abv() OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 41736)
-- Name: prumernehodnocenipivovaru(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.prumernehodnocenipivovaru(pivovar_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    prumer NUMERIC;
BEGIN
    SELECT COALESCE (AVG(R.Hodnoceni), 0) INTO prumer
    FROM Recenze R
    JOIN Piva P ON R.PivoID = P.PivoID
    WHERE P.PivovarID = pivovar_id;
    RETURN prumer;
END;
$$;


ALTER FUNCTION public.prumernehodnocenipivovaru(pivovar_id integer) OWNER TO postgres;

--
-- TOC entry 242 (class 1255 OID 41728)
-- Name: zobraz_piva(); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.zobraz_piva()
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


ALTER PROCEDURE public.zobraz_piva() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 25239)
-- Name: piva; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.piva (
    pivoid integer NOT NULL,
    nazev character varying(255) NOT NULL,
    typid integer,
    abv numeric(4,2),
    ibu integer,
    pivovarid integer
);


ALTER TABLE public.piva OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 25223)
-- Name: pivovary; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pivovary (
    pivovarid integer NOT NULL,
    nazev character varying(255) NOT NULL,
    lokace character varying(255),
    zalozen integer
);


ALTER TABLE public.pivovary OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 25328)
-- Name: agregatni_funkce_a_having; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.agregatni_funkce_a_having AS
 SELECT pivovary.nazev,
    count(piva.pivoid) AS count
   FROM (public.pivovary
     JOIN public.piva ON ((pivovary.pivovarid = piva.pivovarid)))
  GROUP BY pivovary.nazev
 HAVING (count(piva.pivoid) > 2)
  ORDER BY (count(piva.pivoid)) DESC;


ALTER VIEW public.agregatni_funkce_a_having OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 41764)
-- Name: audit_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.audit_log (
    logid integer NOT NULL,
    tabulka character varying(255),
    akce character varying(10),
    pivoid integer,
    predchozi_hodnota character varying(255),
    nova_hodnota character varying(255),
    datum_cas timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "uživatel" character varying(255)
);


ALTER TABLE public.audit_log OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 41763)
-- Name: audit_log_logid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.audit_log_logid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.audit_log_logid_seq OWNER TO postgres;

--
-- TOC entry 5015 (class 0 OID 0)
-- Dependencies: 234
-- Name: audit_log_logid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.audit_log_logid_seq OWNED BY public.audit_log.logid;


--
-- TOC entry 227 (class 1259 OID 25291)
-- Name: recenze; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.recenze (
    recenzeid integer NOT NULL,
    pivoid integer,
    uzivatelid integer,
    hodnoceni integer,
    komentar text,
    CONSTRAINT recenze_hodnoceni_check CHECK (((hodnoceni >= 1) AND (hodnoceni <= 5)))
);


ALTER TABLE public.recenze OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 25324)
-- Name: left_join; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.left_join AS
 SELECT piva.nazev,
    recenze.komentar
   FROM (public.piva
     LEFT JOIN public.recenze ON ((piva.pivoid = recenze.pivoid)));


ALTER VIEW public.left_join OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 25262)
-- Name: nutricni_hodnoty; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nutricni_hodnoty (
    pivoid integer NOT NULL,
    zivinaid integer NOT NULL,
    mnozstvi numeric(10,2)
);


ALTER TABLE public.nutricni_hodnoty OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 25238)
-- Name: piva_pivoid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.piva_pivoid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.piva_pivoid_seq OWNER TO postgres;

--
-- TOC entry 5016 (class 0 OID 0)
-- Dependencies: 219
-- Name: piva_pivoid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.piva_pivoid_seq OWNED BY public.piva.pivoid;


--
-- TOC entry 215 (class 1259 OID 25222)
-- Name: pivovary_pivovarid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pivovary_pivovarid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pivovary_pivovarid_seq OWNER TO postgres;

--
-- TOC entry 5017 (class 0 OID 0)
-- Dependencies: 215
-- Name: pivovary_pivovarid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pivovary_pivovarid_seq OWNED BY public.pivovary.pivovarid;


--
-- TOC entry 240 (class 1259 OID 41893)
-- Name: prehled_piv; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.prehled_piv AS
 SELECT p.nazev AS nazev_piva,
    pv.nazev AS nazev_pivovaru,
    avg(r.hodnoceni) AS prumerne_hodnoceni,
    count(r.recenzeid) AS pocet_recenzi
   FROM ((public.piva p
     JOIN public.pivovary pv ON ((p.pivovarid = pv.pivovarid)))
     LEFT JOIN public.recenze r ON ((p.pivoid = r.pivoid)))
  GROUP BY p.nazev, pv.nazev;


ALTER VIEW public.prehled_piv OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 25290)
-- Name: recenze_recenzeid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.recenze_recenzeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.recenze_recenzeid_seq OWNER TO postgres;

--
-- TOC entry 5018 (class 0 OID 0)
-- Dependencies: 226
-- Name: recenze_recenzeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.recenze_recenzeid_seq OWNED BY public.recenze.recenzeid;


--
-- TOC entry 237 (class 1259 OID 41776)
-- Name: sklad; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sklad (
    skladid integer NOT NULL,
    pivovarid integer NOT NULL,
    surovina character varying(50) NOT NULL,
    mnozstvi numeric(10,2) NOT NULL,
    jednotka character varying(20) NOT NULL,
    datum_posledni_dodavky date
);


ALTER TABLE public.sklad OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 41812)
-- Name: sklad_log; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sklad_log (
    logid integer NOT NULL,
    cas_zmeny timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    akce character varying(10) NOT NULL,
    surovina character varying(255) NOT NULL,
    skladid integer NOT NULL,
    puvodni_mnozstvi numeric(10,2),
    nove_mnozstvi numeric(10,2)
);


ALTER TABLE public.sklad_log OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 41811)
-- Name: sklad_log_logid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sklad_log_logid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sklad_log_logid_seq OWNER TO postgres;

--
-- TOC entry 5021 (class 0 OID 0)
-- Dependencies: 238
-- Name: sklad_log_logid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sklad_log_logid_seq OWNED BY public.sklad_log.logid;


--
-- TOC entry 236 (class 1259 OID 41775)
-- Name: sklad_skladid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sklad_skladid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sklad_skladid_seq OWNER TO postgres;

--
-- TOC entry 5023 (class 0 OID 0)
-- Dependencies: 236
-- Name: sklad_skladid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sklad_skladid_seq OWNED BY public.sklad.skladid;


--
-- TOC entry 218 (class 1259 OID 25232)
-- Name: typy; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.typy (
    typid integer NOT NULL,
    nazev character varying(255) NOT NULL
);


ALTER TABLE public.typy OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 25231)
-- Name: typy_typid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.typy_typid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.typy_typid_seq OWNER TO postgres;

--
-- TOC entry 5025 (class 0 OID 0)
-- Dependencies: 217
-- Name: typy_typid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.typy_typid_seq OWNED BY public.typy.typid;


--
-- TOC entry 229 (class 1259 OID 25311)
-- Name: udalosti; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.udalosti (
    udalostid integer NOT NULL,
    nazev character varying(255) NOT NULL,
    lokace character varying(255),
    datum date,
    cas character varying(5),
    pivovarid integer
);


ALTER TABLE public.udalosti OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 25310)
-- Name: udalosti_udalostid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.udalosti_udalostid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.udalosti_udalostid_seq OWNER TO postgres;

--
-- TOC entry 5026 (class 0 OID 0)
-- Dependencies: 228
-- Name: udalosti_udalostid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.udalosti_udalostid_seq OWNED BY public.udalosti.udalostid;


--
-- TOC entry 225 (class 1259 OID 25278)
-- Name: uzivatele; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.uzivatele (
    uzivatelid integer NOT NULL,
    uzivatelske_jmeno character varying(255) NOT NULL,
    email character varying(255) NOT NULL
);


ALTER TABLE public.uzivatele OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 25277)
-- Name: uzivatele_uzivatelid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.uzivatele_uzivatelid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.uzivatele_uzivatelid_seq OWNER TO postgres;

--
-- TOC entry 5027 (class 0 OID 0)
-- Dependencies: 224
-- Name: uzivatele_uzivatelid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.uzivatele_uzivatelid_seq OWNED BY public.uzivatele.uzivatelid;


--
-- TOC entry 233 (class 1259 OID 41741)
-- Name: zamestnanci; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zamestnanci (
    zamestnanecid integer NOT NULL,
    jmeno_a_prijmeni character varying(255) NOT NULL,
    pozice character varying(100) NOT NULL,
    uzivatelske_jmeno character varying(100) NOT NULL,
    heslo character varying(100) NOT NULL,
    pivovarid integer NOT NULL,
    nadrizena_osoba integer
);


ALTER TABLE public.zamestnanci OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 41740)
-- Name: zamestnanci_zamestnanecid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.zamestnanci_zamestnanecid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.zamestnanci_zamestnanecid_seq OWNER TO postgres;

--
-- TOC entry 5029 (class 0 OID 0)
-- Dependencies: 232
-- Name: zamestnanci_zamestnanecid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.zamestnanci_zamestnanecid_seq OWNED BY public.zamestnanci.zamestnanecid;


--
-- TOC entry 222 (class 1259 OID 25256)
-- Name: ziviny; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ziviny (
    zivinaid integer NOT NULL,
    nazev character varying(255) NOT NULL
);


ALTER TABLE public.ziviny OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 25255)
-- Name: ziviny_zivinaid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ziviny_zivinaid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ziviny_zivinaid_seq OWNER TO postgres;

--
-- TOC entry 5030 (class 0 OID 0)
-- Dependencies: 221
-- Name: ziviny_zivinaid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ziviny_zivinaid_seq OWNED BY public.ziviny.zivinaid;


--
-- TOC entry 4769 (class 2604 OID 41767)
-- Name: audit_log logid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN logid SET DEFAULT nextval('public.audit_log_logid_seq'::regclass);


--
-- TOC entry 4763 (class 2604 OID 25242)
-- Name: piva pivoid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piva ALTER COLUMN pivoid SET DEFAULT nextval('public.piva_pivoid_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 25226)
-- Name: pivovary pivovarid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pivovary ALTER COLUMN pivovarid SET DEFAULT nextval('public.pivovary_pivovarid_seq'::regclass);


--
-- TOC entry 4766 (class 2604 OID 25294)
-- Name: recenze recenzeid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recenze ALTER COLUMN recenzeid SET DEFAULT nextval('public.recenze_recenzeid_seq'::regclass);


--
-- TOC entry 4771 (class 2604 OID 41779)
-- Name: sklad skladid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sklad ALTER COLUMN skladid SET DEFAULT nextval('public.sklad_skladid_seq'::regclass);


--
-- TOC entry 4772 (class 2604 OID 41815)
-- Name: sklad_log logid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sklad_log ALTER COLUMN logid SET DEFAULT nextval('public.sklad_log_logid_seq'::regclass);


--
-- TOC entry 4762 (class 2604 OID 25235)
-- Name: typy typid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.typy ALTER COLUMN typid SET DEFAULT nextval('public.typy_typid_seq'::regclass);


--
-- TOC entry 4767 (class 2604 OID 25314)
-- Name: udalosti udalostid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.udalosti ALTER COLUMN udalostid SET DEFAULT nextval('public.udalosti_udalostid_seq'::regclass);


--
-- TOC entry 4765 (class 2604 OID 25281)
-- Name: uzivatele uzivatelid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uzivatele ALTER COLUMN uzivatelid SET DEFAULT nextval('public.uzivatele_uzivatelid_seq'::regclass);


--
-- TOC entry 4768 (class 2604 OID 41744)
-- Name: zamestnanci zamestnanecid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zamestnanci ALTER COLUMN zamestnanecid SET DEFAULT nextval('public.zamestnanci_zamestnanecid_seq'::regclass);


--
-- TOC entry 4764 (class 2604 OID 25259)
-- Name: ziviny zivinaid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ziviny ALTER COLUMN zivinaid SET DEFAULT nextval('public.ziviny_zivinaid_seq'::regclass);


--
-- TOC entry 5004 (class 0 OID 41764)
-- Dependencies: 235
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.audit_log (logid, tabulka, akce, pivoid, predchozi_hodnota, nova_hodnota, datum_cas, "uživatel") FROM stdin;
1	Piva	UPDATE	1	Pilsner Urquell	Plzeň	2024-12-10 16:14:11.049795	postgres
2	Piva	UPDATE	1	Plzeň	Pilsner Urquell	2024-12-10 16:15:14.377568	postgres
3	Piva	UPDATE	1	Pilsner Urquell	Poplzeň	2024-12-17 16:58:19.500467	postgres
4	Piva	UPDATE	1	Poplzeň	Pilsner Urquell	2024-12-17 16:59:22.948174	postgres
\.


--
-- TOC entry 4994 (class 0 OID 25262)
-- Dependencies: 223
-- Data for Name: nutricni_hodnoty; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.nutricni_hodnoty (pivoid, zivinaid, mnozstvi) FROM stdin;
1	1	0.50
1	2	5.10
1	3	0.00
1	4	0.00
2	1	2.50
2	2	17.00
2	3	1.50
2	4	0.05
3	1	2.00
3	2	14.00
3	3	0.00
3	4	0.00
4	1	2.50
4	2	16.50
4	3	0.00
4	4	0.00
5	1	2.50
5	2	32.00
5	3	1.50
5	4	0.00
6	1	2.50
6	2	29.00
6	3	0.00
6	4	0.00
7	1	2.00
7	2	3.50
7	3	0.00
7	4	0.00
8	1	0.00
8	2	19.50
8	3	0.00
8	4	0.50
9	1	0.00
9	2	17.50
9	3	0.00
9	4	0.00
10	1	3.95
10	2	12.00
10	3	0.50
10	4	0.00
11	1	4.35
11	2	15.00
11	3	0.50
11	4	0.03
12	1	2.50
12	2	25.00
12	3	0.00
12	4	0.00
13	1	2.90
13	2	27.00
13	3	0.50
13	4	0.05
14	1	2.50
14	2	18.50
14	3	0.00
14	4	0.05
15	1	2.50
15	2	15.00
15	3	0.00
15	4	0.00
16	1	4.50
16	2	21.50
16	3	1.00
16	4	0.05
17	1	4.30
17	2	19.50
17	3	0.00
17	4	0.05
18	1	3.00
18	2	4.10
18	3	0.00
18	4	0.05
19	1	2.50
19	2	18.50
19	3	0.00
19	4	0.05
20	1	2.50
20	2	15.50
20	3	0.00
20	4	0.00
21	1	2.50
21	2	18.50
21	3	0.00
21	4	0.00
22	1	2.50
22	2	5.00
22	3	0.00
22	4	0.00
23	1	2.50
23	2	14.50
23	3	0.00
23	4	0.05
24	1	2.50
24	2	17.50
24	3	0.00
24	4	0.05
25	1	2.50
25	2	14.50
25	3	0.00
25	4	0.05
26	1	2.50
26	2	23.50
26	3	0.00
26	4	0.05
27	1	2.50
27	2	13.00
27	3	0.00
27	4	0.05
28	1	2.50
28	2	16.00
28	3	0.00
28	4	0.05
29	1	3.25
29	2	18.50
29	3	0.00
29	4	0.00
30	1	0.50
30	2	3.90
30	3	0.00
30	4	0.02
31	1	2.50
31	2	26.50
31	3	0.00
31	4	0.10
32	1	1.86
32	2	17.30
32	3	0.00
32	4	0.00
33	1	2.25
33	2	16.80
33	3	0.00
33	4	0.35
34	1	2.50
34	2	18.50
34	3	0.00
34	4	0.00
35	1	3.50
35	2	21.00
35	3	0.00
35	4	0.00
36	1	2.50
36	2	33.00
36	3	0.00
36	4	0.00
37	1	1.90
37	2	13.90
37	3	0.00
37	4	0.08
38	1	0.50
38	2	25.00
38	3	0.00
38	4	0.00
39	1	0.25
39	2	14.50
39	3	0.05
39	4	0.05
40	1	1.00
40	2	22.00
40	3	0.00
40	4	0.00
41	1	2.00
41	2	15.90
41	3	0.00
41	4	0.05
42	1	0.50
42	2	0.50
42	3	0.50
42	4	0.00
43	1	1.00
43	2	15.00
43	3	0.50
43	4	0.00
44	1	0.00
44	2	11.50
44	3	0.00
44	4	0.00
45	1	0.50
45	2	11.50
45	3	0.50
45	4	0.05
46	1	5.00
46	2	60.00
46	3	0.00
46	4	0.00
47	1	0.40
47	2	17.00
47	3	0.00
47	4	0.50
48	1	1.30
48	2	24.00
48	3	0.00
48	4	0.14
49	1	0.30
49	2	11.10
49	3	0.00
49	4	0.50
50	1	2.50
50	2	16.00
50	3	0.00
50	4	0.00
51	1	0.40
51	2	21.10
51	3	0.00
51	4	0.02
\.


--
-- TOC entry 4991 (class 0 OID 25239)
-- Dependencies: 220
-- Data for Name: piva; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.piva (pivoid, nazev, typid, abv, ibu, pivovarid) FROM stdin;
2	Excelent 11°	1	4.70	27	1
3	Velkopopovický Kozel Světlý	2	4.00	22	2
4	Velkopopovický Kozel 11°	1	4.60	26	2
5	Velkopopovický Kozel Černý	3	3.80	15	2
6	Velkopopovický Kozel Nealko	4	0.50	20	2
7	Radegast Rázná 10°	2	4.20	30	3
8	Radegast Ryze Hořká 12°	1	5.10	36	3
9	Radegast Ratar	1	5.00	50	3
10	Staropramen Desítka	1	4.00	30	4
11	Staropramen Jedenáctka	1	4.70	25	4
12	Staropramen Dvanáctka	1	5.20	32	4
13	Staropramen Nealko Pivo	4	0.50	26	4
14	Svijanská Desítka	2	4.00	30	5
15	Svijanský Máz	1	4.80	31	5
16	Svijanská Kněžna	3	5.20	43	5
17	Svijanský Kníže	1	5.60	42	5
18	Svijanský Baron	1	6.50	46	5
19	Svijanský Vozka	4	0.50	22	5
20	Gambrinus Originál	2	4.30	24	6
21	Gambrinus 12°	2	5.20	29	6
22	Gambrinus Dry	2	4.00	18	6
23	Krušovice 10°	1	4.20	24	7
24	Krušovice 12°	1	5.00	33	7
25	Krušovice Bohém	1	4.70	37	7
26	Krušovice Hořké Nealko	4	0.50	28	7
27	Braník	2	4.10	30	4
28	Braník Jedenáctka	2	4.80	32	4
29	Ferdinand Premium 12°	1	5.00	30	8
30	Ostravar Mustang	1	4.90	33	9
31	Ostravar Černá Barbora	3	5.10	28	9
32	Holba Horská 10°	2	4.70	24	10
33	Holba Šerák	1	4.70	29	10
34	Bernard Světlé Výčepní 10°	2	3.80	25	11
35	Bernard Extra Hořký Ležák 12°	1	4.90	37	11
36	Bernard Švestka Nealkoholické pivo	4	0.50	23	11
37	Litovel 12°	1	5.00	22	12
38	Litovel Gustav	4	6.10	35	12
39	Platan Jedenáctka	1	4.60	30	13
40	Platan Nealkoholické Pivo	4	0.50	26	13
41	Uherský brod Patriot 11°	1	4.50	27	14
42	Ježek Jedenáctka	1	4.80	32	15
43	Klášter Světlé	2	4.00	24	16
44	Klášter Premium	1	5.00	27	16
45	Klášter Ležák	1	4.60	28	16
46	Rychtář Premium	1	5.00	30	17
47	Lobkowicz Démon	3	5.20	26	18
48	Lobkowicz Nealkoholický	4	0.50	26	18
49	Černá hora Tmavý ležák	3	4.50	22	19
50	Černá hora Granát	3	4.50	22	19
51	Proud Ležák	1	3.90	18	20
1	Pilsner Urquell	1	4.40	39	1
\.


--
-- TOC entry 4987 (class 0 OID 25223)
-- Dependencies: 216
-- Data for Name: pivovary; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.pivovary (pivovarid, nazev, lokace, zalozen) FROM stdin;
1	Plzeňský prazdroj	Plzeň	1842
2	Pivovar Velké Popovice	Velké Popovice	1874
3	Pivovar Radegast	Nošovice	1970
4	Smíchovský Pivovar	Praha	1871
5	Pivovar Svijany	Svijany	1564
6	Pivovar Gambrinus	Plzeň	1969
7	Královský Pivovar Krušovice	Krušovice	1517
8	Pivovar Ferdinand	Benešov	1897
9	Pivovar Ostravar	Ostravar	1897
10	Pivovar Holba	Hanušovice	1874
11	Rodinný Pivovar Bernard	Humpolec	1597
12	Pivovar Litovel 	Litovel	1893
13	Pivovar Protivín	Protivín	1598
14	Pivovar Uherský Brod	Uherský Brod	1894
15	Pivovar Jihlava	Jihlava	1994
16	Pivovar Klášter	Klášter Hradiště nad Jizerou	1570
17	Pivovar Rychtář	Hlinsko	1913
18	Pivovar Vysoký Chlumec	Vysoký Chlumec	1992
19	Pivovar Černá Hora	Černá Hora	1298
20	Minipivovar Proud	Plzeň	2020
1000	United Breweries	New York	1857
\.


--
-- TOC entry 4998 (class 0 OID 25291)
-- Dependencies: 227
-- Data for Name: recenze; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.recenze (recenzeid, pivoid, uzivatelid, hodnoceni, komentar) FROM stdin;
1	1	1	4	Plzeň je opravdu lahodné pivo.
2	3	2	3	Dobrá chuť a vůně.
3	4	3	5	Kozel 11° je ideální pro letní večery. Lehká chuť a příjemná vůně.
4	17	4	4	Svijanský kníže má velmi zajímavý charakter. Určitě si ho koupím znovu.
5	9	5	2	Po ochutnání Ratara jsem nebyl nadšen.
6	28	6	5	Braník Jedenáctka je prostě vynikající. Skvělá volba pro milovníky kvalitního piva.
7	36	7	1	Bernard švestka neměla všechno, co od piva očekávám.
8	43	8	4	Klášter mě zaujal svou svěžestí a jemnou hořkostí. Doporučuji všem.
9	51	9	5	Perfektní pivo! Ležák od Proudu měl skvělou pěnu a vyváženou chuť.
10	33	10	3	Holba Šerák měla překvapivě lahodnou chuť.
11	20	11	4	Byl jsem velmi spokojen s Gambrinusem.
12	25	12	3	Výborná chuť a vůně.
13	29	13	4	Ferinand je ideální volba pro každou příležitost.
14	35	14	1	
15	37	15	4	Skvělé pivo! Litovel má vyváženou chuť a příjemnou hořkost.
16	42	16	3	Možná si ho koupím znovu.
17	1	17	4	Doporučuji.
18	41	18	5	Patriot měl výbornou chuť a krásnou barvu.
19	1	19	5	Jedno z nejlepších piv
20	47	20	4	Byla jsem velmi spokojená
\.


--
-- TOC entry 5006 (class 0 OID 41776)
-- Dependencies: 237
-- Data for Name: sklad; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sklad (skladid, pivovarid, surovina, mnozstvi, jednotka, datum_posledni_dodavky) FROM stdin;
2	1	Slad	500.00	Kg	2024-12-08
3	1	Chmel	200.00	Kg	2024-12-09
6	2	Slad	400.00	Kg	2024-11-27
7	2	Kvasnice	70.00	Kg	2024-10-13
4	1	Kvasnice	150.00	Kg	2024-12-11
5	2	Voda	14000.00	Litry	2024-12-11
1	1	Voda	3500.00	Litry	2024-12-10
\.


--
-- TOC entry 5008 (class 0 OID 41812)
-- Dependencies: 239
-- Data for Name: sklad_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sklad_log (logid, cas_zmeny, akce, surovina, skladid, puvodni_mnozstvi, nove_mnozstvi) FROM stdin;
1	2024-12-13 19:10:15.099941	UPDATE	Voda	1	10000.00	9000.00
5	2024-12-13 19:20:57.58879	UPDATE	Voda	1	9000.00	4000.00
6	2024-12-13 19:20:57.58879	UPDATE	Voda	5	5000.00	10000.00
8	2024-12-13 19:23:38.833054	UPDATE	Voda	5	10000.00	5000.00
9	2024-12-13 19:23:38.833054	UPDATE	Voda	1	4000.00	9000.00
10	2024-12-13 20:58:09.345321	UPDATE	Voda	1	9000.00	10000.00
11	2024-12-13 22:02:33.330298	UPDATE	Voda	1	10000.00	9000.00
12	2024-12-13 22:08:29.537224	UPDATE	Voda	1	9000.00	4000.00
13	2024-12-13 22:08:29.537224	UPDATE	Voda	5	5000.00	10000.00
14	2024-12-14 01:18:30.366655	UPDATE	Voda	1	4000.00	3000.00
15	2024-12-14 01:22:43.417131	UPDATE	Voda	5	10000.00	9000.00
16	2024-12-14 01:30:06.060961	UPDATE	Kvasnice	5	50.00	150.00
17	2024-12-17 17:10:17.450743	UPDATE	Voda	1	3000.00	9000.00
18	2024-12-17 17:10:28.132074	UPDATE	Voda	1	9000.00	4000.00
19	2024-12-17 17:10:28.132074	UPDATE	Voda	5	9000.00	14000.00
20	2024-12-17 17:20:06.170599	UPDATE	Voda	1	4000.00	3500.00
\.


--
-- TOC entry 4989 (class 0 OID 25232)
-- Dependencies: 218
-- Data for Name: typy; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.typy (typid, nazev) FROM stdin;
1	Světlý ležák
2	Světlé výčepní pivo
3	Tmavé pivo
4	Nealkoholické pivo
\.


--
-- TOC entry 5000 (class 0 OID 25311)
-- Dependencies: 229
-- Data for Name: udalosti; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.udalosti (udalostid, nazev, lokace, datum, cas, pivovarid) FROM stdin;
1	Ochutnejte Pivo na náplavce!	Praha 2, Náplavka	2024-06-12	14:50	20
2	Setkání pivovarů v Rosicích 2024	Zámek Rosice	2024-07-20	09:00	2
3	Pivofest Pivních stezek Lužických hor	Letní Kino Cvikov	2024-06-22	06:00	5
4	Pivní festival Gambrinusu: Dejte si pivo do skla na největší pivní zahrádce	Pivovar Gambrinus, Plzeň	2019-06-18	12:10	6
5	Přijďte na pivo! Český pivní festival v Praze začíná	Letenská Pláň, Praha	2018-05-10	00:00	13
6	Pivní festival patří mezi nejlepší akce na světě	Výstaviště, Praha-Holešovice	2012-01-21	16:20	4
7	Oktobeerfest, to je pivní festival a zábava v Ostravě	Ostrava-Vítkovice	2019-10-11	19:54	9
8	Tišnovská pivní stezka	Tišnov, Jihomoravský Kraj	2023-02-17	13:30	11
9	Gastroakce i pivní a vinařské slavnosti, které si nenechat v květnu ujít	Litomyšl	2024-05-14	10:00	12
10	Prima Fresh festival 2024 v Pardubicích	Pardubice	2024-06-22	17:20	19
11	Retro filmový festival Kino jede 2024	Náměšť nad Oslavou	2024-06-27	20:30	16
12	Velký pivní festival připravují v Jihlavě	Jihlava	2013-07-15	20:00	15
13	Přes 70 druhů piv v Praze na jednom místě	Letenská Pláň, Praha	2017-05-16	05:10	4
14	Pivovarské muzeum Plzeň – nejstarší muzeum piva na světě	Plzeň, Plzeňský Kraj	2016-05-08	00:00	1
15	Festival Žižkovské pivobraní 	Praha Žižkov	2023-05-03	12:00	20
16	Speciální lahůdky Fresh festivalu ochutnáte v Uherském Brodě	Uherský Brod	2019-05-22	09:30	14
17	Pivní slavnosti nabídnou pivo, hudbu a skvělou zábavu	Třeboň	2017-07-16	10:00	18
18	Festival minipivovarů ovládne Pražský hrad	Pražský hrad, Praha 1	2024-05-06	13:00	7
19	Pivní fest a Burger fest Telč 2024	Telč, Kraj Vysočina	2024-07-13	08:00	10
20	Treffpunkt přiváží Bavorsko do Plzně!	Plzeň	2024-04-23	15:40	6
\.


--
-- TOC entry 4996 (class 0 OID 25278)
-- Dependencies: 225
-- Data for Name: uzivatele; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.uzivatele (uzivatelid, uzivatelske_jmeno, email) FROM stdin;
1	Jan Novák	jan.novak@example.com
2	Petra Svobodová	petra.svobodova@example.com
3	Karel Dvořák	karel.dvorak@example.com
4	Eva Novotná	eva.novotna@example.com
5	Miroslav Kučera	miroslav.kucera@example.com
6	Alena Veselá	alena.vesela@example.com
7	Tomáš Malý	tomas.maly@example.com
8	Hana Krejčí	hana.krejci@example.com
9	Petr Pokorný	petr.pokorny@example.com
10	Jana Králová	jana.kralova@example.com
11	Martin Černý	martin.cerny@example.com
12	Lucie56	lucie.1956@example.com
13	Jaroslav Marek	jaroslav.marek@example.com
14	Iveta_3_	iveta3@example.com
15	Pan Holý	holy@example.com
16	Radek Havel	radek.havel@example.com
17	Vyskočilová	vyskocilova@example.com
18	Pavla	pavla1@example.com
19	Roman Janda	roman.janda@example.com
20	Simona Němcová	simona.nemcova@example.com
\.


--
-- TOC entry 5002 (class 0 OID 41741)
-- Dependencies: 233
-- Data for Name: zamestnanci; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zamestnanci (zamestnanecid, jmeno_a_prijmeni, pozice, uzivatelske_jmeno, heslo, pivovarid, nadrizena_osoba) FROM stdin;
1	Jan Novák	Vedoucí výroby	jnovak	heslo123	1	\N
2	Petra Dvořáková	Sládek	pdvorakova	tajneheslo	1	1
3	Karel Svoboda	Pomocný pracovník	ksvoboda	mojeheslo	1	2
4	Alena Novotná	Vedoucí výroby	anovotna	admin123	2	\N
5	Petr Malý	Sládek	pmaly	12345	2	4
6	Karel Vomáčka	Vedoucí skladu	skladadmin	sklad123	1000	\N
7	postgres	Administrátor	postgres	toor	1000	\N
\.


--
-- TOC entry 4993 (class 0 OID 25256)
-- Dependencies: 222
-- Data for Name: ziviny; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ziviny (zivinaid, nazev) FROM stdin;
1	Bílkoviny
2	Sacharidy
3	Tuky
4	Sůl
\.


--
-- TOC entry 5031 (class 0 OID 0)
-- Dependencies: 234
-- Name: audit_log_logid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.audit_log_logid_seq', 4, true);


--
-- TOC entry 5032 (class 0 OID 0)
-- Dependencies: 219
-- Name: piva_pivoid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.piva_pivoid_seq', 51, true);


--
-- TOC entry 5033 (class 0 OID 0)
-- Dependencies: 215
-- Name: pivovary_pivovarid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.pivovary_pivovarid_seq', 20, true);


--
-- TOC entry 5034 (class 0 OID 0)
-- Dependencies: 226
-- Name: recenze_recenzeid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.recenze_recenzeid_seq', 20, true);


--
-- TOC entry 5035 (class 0 OID 0)
-- Dependencies: 238
-- Name: sklad_log_logid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sklad_log_logid_seq', 20, true);


--
-- TOC entry 5036 (class 0 OID 0)
-- Dependencies: 236
-- Name: sklad_skladid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sklad_skladid_seq', 12, true);


--
-- TOC entry 5037 (class 0 OID 0)
-- Dependencies: 217
-- Name: typy_typid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.typy_typid_seq', 4, true);


--
-- TOC entry 5038 (class 0 OID 0)
-- Dependencies: 228
-- Name: udalosti_udalostid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.udalosti_udalostid_seq', 20, true);


--
-- TOC entry 5039 (class 0 OID 0)
-- Dependencies: 224
-- Name: uzivatele_uzivatelid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.uzivatele_uzivatelid_seq', 20, true);


--
-- TOC entry 5040 (class 0 OID 0)
-- Dependencies: 232
-- Name: zamestnanci_zamestnanecid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zamestnanci_zamestnanecid_seq', 7, true);


--
-- TOC entry 5041 (class 0 OID 0)
-- Dependencies: 221
-- Name: ziviny_zivinaid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ziviny_zivinaid_seq', 4, true);


--
-- TOC entry 4801 (class 2606 OID 41772)
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (logid);


--
-- TOC entry 4784 (class 2606 OID 25266)
-- Name: nutricni_hodnoty nutricni_hodnoty_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nutricni_hodnoty
    ADD CONSTRAINT nutricni_hodnoty_pkey PRIMARY KEY (pivoid, zivinaid);


--
-- TOC entry 4780 (class 2606 OID 25244)
-- Name: piva piva_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piva
    ADD CONSTRAINT piva_pkey PRIMARY KEY (pivoid);


--
-- TOC entry 4776 (class 2606 OID 25230)
-- Name: pivovary pivovary_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pivovary
    ADD CONSTRAINT pivovary_pkey PRIMARY KEY (pivovarid);


--
-- TOC entry 4793 (class 2606 OID 25299)
-- Name: recenze recenze_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recenze
    ADD CONSTRAINT recenze_pkey PRIMARY KEY (recenzeid);


--
-- TOC entry 4806 (class 2606 OID 41818)
-- Name: sklad_log sklad_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sklad_log
    ADD CONSTRAINT sklad_log_pkey PRIMARY KEY (logid);


--
-- TOC entry 4803 (class 2606 OID 41781)
-- Name: sklad sklad_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sklad
    ADD CONSTRAINT sklad_pkey PRIMARY KEY (skladid);


--
-- TOC entry 4778 (class 2606 OID 25237)
-- Name: typy typy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.typy
    ADD CONSTRAINT typy_pkey PRIMARY KEY (typid);


--
-- TOC entry 4795 (class 2606 OID 25318)
-- Name: udalosti udalosti_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.udalosti
    ADD CONSTRAINT udalosti_pkey PRIMARY KEY (udalostid);


--
-- TOC entry 4787 (class 2606 OID 25289)
-- Name: uzivatele uzivatele_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uzivatele
    ADD CONSTRAINT uzivatele_email_key UNIQUE (email);


--
-- TOC entry 4789 (class 2606 OID 25285)
-- Name: uzivatele uzivatele_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uzivatele
    ADD CONSTRAINT uzivatele_pkey PRIMARY KEY (uzivatelid);


--
-- TOC entry 4791 (class 2606 OID 25287)
-- Name: uzivatele uzivatele_uzivatelske_nazev_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.uzivatele
    ADD CONSTRAINT uzivatele_uzivatelske_nazev_key UNIQUE (uzivatelske_jmeno);


--
-- TOC entry 4797 (class 2606 OID 41748)
-- Name: zamestnanci zamestnanci_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_pkey PRIMARY KEY (zamestnanecid);


--
-- TOC entry 4799 (class 2606 OID 41750)
-- Name: zamestnanci zamestnanci_uzivatelske_jmeno_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_uzivatelske_jmeno_key UNIQUE (uzivatelske_jmeno);


--
-- TOC entry 4782 (class 2606 OID 25261)
-- Name: ziviny ziviny_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ziviny
    ADD CONSTRAINT ziviny_pkey PRIMARY KEY (zivinaid);


--
-- TOC entry 4785 (class 1259 OID 41735)
-- Name: idx_uzivatele_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX idx_uzivatele_email ON public.uzivatele USING btree (email);


--
-- TOC entry 4804 (class 1259 OID 41826)
-- Name: sklad_surovina_pivovarid_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX sklad_surovina_pivovarid_idx ON public.sklad USING btree (surovina, pivovarid);


--
-- TOC entry 4818 (class 2620 OID 41774)
-- Name: piva trg_auditpivaupdate; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_auditpivaupdate AFTER UPDATE ON public.piva FOR EACH ROW EXECUTE FUNCTION public.auditpivaupdate();


--
-- TOC entry 4819 (class 2620 OID 41825)
-- Name: sklad trg_skladlog; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_skladlog AFTER INSERT OR DELETE OR UPDATE ON public.sklad FOR EACH ROW EXECUTE FUNCTION public.logskladchanges();


--
-- TOC entry 4809 (class 2606 OID 25267)
-- Name: nutricni_hodnoty nutricni_hodnoty_pivoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nutricni_hodnoty
    ADD CONSTRAINT nutricni_hodnoty_pivoid_fkey FOREIGN KEY (pivoid) REFERENCES public.piva(pivoid);


--
-- TOC entry 4810 (class 2606 OID 25272)
-- Name: nutricni_hodnoty nutricni_hodnoty_zivinaid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nutricni_hodnoty
    ADD CONSTRAINT nutricni_hodnoty_zivinaid_fkey FOREIGN KEY (zivinaid) REFERENCES public.ziviny(zivinaid);


--
-- TOC entry 4807 (class 2606 OID 25245)
-- Name: piva piva_pivovarid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piva
    ADD CONSTRAINT piva_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid);


--
-- TOC entry 4808 (class 2606 OID 25250)
-- Name: piva piva_typid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.piva
    ADD CONSTRAINT piva_typid_fkey FOREIGN KEY (typid) REFERENCES public.typy(typid);


--
-- TOC entry 4811 (class 2606 OID 25300)
-- Name: recenze recenze_pivoid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recenze
    ADD CONSTRAINT recenze_pivoid_fkey FOREIGN KEY (pivoid) REFERENCES public.piva(pivoid);


--
-- TOC entry 4812 (class 2606 OID 25305)
-- Name: recenze recenze_uzivatelid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.recenze
    ADD CONSTRAINT recenze_uzivatelid_fkey FOREIGN KEY (uzivatelid) REFERENCES public.uzivatele(uzivatelid);


--
-- TOC entry 4817 (class 2606 OID 41819)
-- Name: sklad_log sklad_log_skladid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sklad_log
    ADD CONSTRAINT sklad_log_skladid_fkey FOREIGN KEY (skladid) REFERENCES public.sklad(skladid);


--
-- TOC entry 4816 (class 2606 OID 41782)
-- Name: sklad sklad_pivovarid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sklad
    ADD CONSTRAINT sklad_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid) ON DELETE CASCADE;


--
-- TOC entry 4813 (class 2606 OID 25319)
-- Name: udalosti udalosti_pivovarid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.udalosti
    ADD CONSTRAINT udalosti_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid);


--
-- TOC entry 4814 (class 2606 OID 41756)
-- Name: zamestnanci zamestnanci_nadrizena_osoba_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_nadrizena_osoba_fkey FOREIGN KEY (nadrizena_osoba) REFERENCES public.zamestnanci(zamestnanecid);


--
-- TOC entry 4815 (class 2606 OID 41751)
-- Name: zamestnanci zamestnanci_pivovarid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid);


--
-- TOC entry 4968 (class 3256 OID 41861)
-- Name: sklad manager_1_sklad; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY manager_1_sklad ON public.sklad FOR SELECT TO manager_1 USING ((pivovarid = 1));


--
-- TOC entry 4969 (class 3256 OID 41862)
-- Name: sklad_log manager_1_sklad_log; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY manager_1_sklad_log ON public.sklad_log FOR SELECT TO manager_1 USING ((skladid = 1));


--
-- TOC entry 4970 (class 3256 OID 41865)
-- Name: sklad manager_2_sklad; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY manager_2_sklad ON public.sklad FOR SELECT TO manager_2 USING ((pivovarid = 2));


--
-- TOC entry 4971 (class 3256 OID 41866)
-- Name: sklad_log manager_2_sklad_log; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY manager_2_sklad_log ON public.sklad_log FOR SELECT TO manager_2 USING ((skladid = 5));


--
-- TOC entry 4966 (class 0 OID 41776)
-- Dependencies: 237
-- Name: sklad; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.sklad ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4967 (class 0 OID 41812)
-- Dependencies: 239
-- Name: sklad_log; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.sklad_log ENABLE ROW LEVEL SECURITY;

--
-- TOC entry 4974 (class 3256 OID 41871)
-- Name: sklad sladek_1_sklad_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_1_sklad_insert ON public.sklad FOR INSERT TO sladek_1 WITH CHECK ((pivovarid = 1));


--
-- TOC entry 4975 (class 3256 OID 41872)
-- Name: sklad_log sladek_1_sklad_log; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_1_sklad_log ON public.sklad_log FOR SELECT TO sladek_1 USING ((skladid = 1));


--
-- TOC entry 4976 (class 3256 OID 41873)
-- Name: sklad_log sladek_1_sklad_log_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_1_sklad_log_insert ON public.sklad_log FOR INSERT TO sladek_1 WITH CHECK ((skladid = 1));


--
-- TOC entry 4977 (class 3256 OID 41874)
-- Name: sklad_log sladek_1_sklad_log_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_1_sklad_log_update ON public.sklad_log FOR UPDATE TO sladek_1 USING ((skladid = 1));


--
-- TOC entry 4972 (class 3256 OID 41869)
-- Name: sklad sladek_1_sklad_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_1_sklad_select ON public.sklad FOR SELECT TO sladek_1 USING ((pivovarid = 1));


--
-- TOC entry 4973 (class 3256 OID 41870)
-- Name: sklad sladek_1_sklad_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_1_sklad_update ON public.sklad FOR UPDATE TO sladek_1 USING ((pivovarid = 1));


--
-- TOC entry 4979 (class 3256 OID 41878)
-- Name: sklad sladek_2_sklad_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_2_sklad_insert ON public.sklad FOR INSERT TO sladek_2 WITH CHECK ((pivovarid = 2));


--
-- TOC entry 4981 (class 3256 OID 41880)
-- Name: sklad_log sladek_2_sklad_log; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_2_sklad_log ON public.sklad_log FOR SELECT TO sladek_2 USING ((skladid = 5));


--
-- TOC entry 4982 (class 3256 OID 41881)
-- Name: sklad_log sladek_2_sklad_log_insert; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_2_sklad_log_insert ON public.sklad_log FOR INSERT TO sladek_2 WITH CHECK ((skladid = 5));


--
-- TOC entry 4983 (class 3256 OID 41882)
-- Name: sklad_log sladek_2_sklad_log_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_2_sklad_log_update ON public.sklad_log FOR UPDATE TO sladek_2 USING ((skladid = 5));


--
-- TOC entry 4978 (class 3256 OID 41877)
-- Name: sklad sladek_2_sklad_select; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_2_sklad_select ON public.sklad FOR SELECT TO sladek_2 USING ((pivovarid = 2));


--
-- TOC entry 4980 (class 3256 OID 41879)
-- Name: sklad sladek_2_sklad_update; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY sladek_2_sklad_update ON public.sklad FOR UPDATE TO sladek_2 USING ((pivovarid = 2));


--
-- TOC entry 4984 (class 3256 OID 41890)
-- Name: sklad warehouse_manager_sklad; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY warehouse_manager_sklad ON public.sklad TO warehouse_manager USING (true);


--
-- TOC entry 4985 (class 3256 OID 41891)
-- Name: sklad_log warehouse_manager_sklad_log; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY warehouse_manager_sklad_log ON public.sklad_log TO warehouse_manager USING (true);


--
-- TOC entry 5014 (class 0 OID 0)
-- Dependencies: 216
-- Name: TABLE pivovary; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.pivovary TO skladadmin;
GRANT SELECT ON TABLE public.pivovary TO jnovak;
GRANT SELECT ON TABLE public.pivovary TO pdvorakova;
GRANT SELECT ON TABLE public.pivovary TO ksvoboda;
GRANT SELECT ON TABLE public.pivovary TO anovotna;
GRANT SELECT ON TABLE public.pivovary TO pmaly;


--
-- TOC entry 5019 (class 0 OID 0)
-- Dependencies: 237
-- Name: TABLE sklad; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.sklad TO jnovak;
GRANT SELECT ON TABLE public.sklad TO anovotna;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad TO pdvorakova;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad TO pmaly;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad TO skladadmin;


--
-- TOC entry 5020 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE sklad_log; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.sklad_log TO anovotna;
GRANT SELECT ON TABLE public.sklad_log TO jnovak;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad_log TO pdvorakova;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad_log TO pmaly;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad_log TO skladadmin;


--
-- TOC entry 5022 (class 0 OID 0)
-- Dependencies: 238
-- Name: SEQUENCE sklad_log_logid_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sklad_log_logid_seq TO skladadmin;
GRANT ALL ON SEQUENCE public.sklad_log_logid_seq TO pdvorakova;
GRANT ALL ON SEQUENCE public.sklad_log_logid_seq TO pmaly;


--
-- TOC entry 5024 (class 0 OID 0)
-- Dependencies: 236
-- Name: SEQUENCE sklad_skladid_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.sklad_skladid_seq TO pdvorakova;
GRANT ALL ON SEQUENCE public.sklad_skladid_seq TO skladadmin;
GRANT ALL ON SEQUENCE public.sklad_skladid_seq TO pmaly;


--
-- TOC entry 5028 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE zamestnanci; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.zamestnanci TO skladadmin;
GRANT SELECT ON TABLE public.zamestnanci TO jnovak;
GRANT SELECT ON TABLE public.zamestnanci TO pdvorakova;
GRANT SELECT ON TABLE public.zamestnanci TO ksvoboda;
GRANT SELECT ON TABLE public.zamestnanci TO anovotna;
GRANT SELECT ON TABLE public.zamestnanci TO pmaly;


-- Completed on 2025-01-02 07:27:34

--
-- PostgreSQL database dump complete
--

