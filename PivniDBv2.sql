PGDMP  $                    |            PivniDB    16.3    16.3 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            �           1262    25165    PivniDB    DATABASE     |   CREATE DATABASE "PivniDB" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Czech_Czechia.1250';
    DROP DATABASE "PivniDB";
                postgres    false            �           0    0    DATABASE "PivniDB"    COMMENT     
  COMMENT ON DATABASE "PivniDB" IS 'Databáze vytvořena jako projekt předmětu Úvod do relačních databází

Zdroje dat:
Udalosti - kudyznudy.cz
Ziviny - kaloricketabulky.cz
Piva - pivniatlas.cz

Data výživových hodnot jsou orientační.
Autor: Pavel Brixí';
                   postgres    false    5014            �            1255    41773    auditpivaupdate()    FUNCTION     �  CREATE FUNCTION public.auditpivaupdate() RETURNS trigger
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
 (   DROP FUNCTION public.auditpivaupdate();
       public          postgres    false            �            1255    41824    logskladchanges()    FUNCTION     F  CREATE FUNCTION public.logskladchanges() RETURNS trigger
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
 (   DROP FUNCTION public.logskladchanges();
       public          postgres    false            �            1255    41739 &   pivavdanemrozmeziabv(numeric, numeric)    FUNCTION     ?  CREATE FUNCTION public.pivavdanemrozmeziabv(spodni_mez numeric, horni_mez numeric) RETURNS TABLE(nazev character varying, abv numeric)
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
 R   DROP FUNCTION public.pivavdanemrozmeziabv(spodni_mez numeric, horni_mez numeric);
       public          postgres    false            �            1255    41737    pocetsilnychpiv()    FUNCTION     �   CREATE FUNCTION public.pocetsilnychpiv() RETURNS integer
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
 (   DROP FUNCTION public.pocetsilnychpiv();
       public          postgres    false            �            1255    41727    prumerna_hodnota_abv()    FUNCTION     �   CREATE FUNCTION public.prumerna_hodnota_abv() RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    prumer_abv NUMERIC;
BEGIN
    SELECT AVG(abv) INTO prumer_abv FROM Piva;
    RETURN prumer_abv;
END;
$$;
 -   DROP FUNCTION public.prumerna_hodnota_abv();
       public          postgres    false            �            1255    41736 "   prumernehodnocenipivovaru(integer)    FUNCTION     F  CREATE FUNCTION public.prumernehodnocenipivovaru(pivovar_id integer) RETURNS numeric
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
 D   DROP FUNCTION public.prumernehodnocenipivovaru(pivovar_id integer);
       public          postgres    false            �            1255    41728    zobraz_piva() 	   PROCEDURE       CREATE PROCEDURE public.zobraz_piva()
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
 %   DROP PROCEDURE public.zobraz_piva();
       public          postgres    false            �            1259    25239    piva    TABLE     �   CREATE TABLE public.piva (
    pivoid integer NOT NULL,
    nazev character varying(255) NOT NULL,
    typid integer,
    abv numeric(4,2),
    ibu integer,
    pivovarid integer
);
    DROP TABLE public.piva;
       public         heap    postgres    false            �            1259    25223    pivovary    TABLE     �   CREATE TABLE public.pivovary (
    pivovarid integer NOT NULL,
    nazev character varying(255) NOT NULL,
    lokace character varying(255),
    zalozen integer
);
    DROP TABLE public.pivovary;
       public         heap    postgres    false            �           0    0    TABLE pivovary    ACL     1  GRANT SELECT ON TABLE public.pivovary TO skladadmin;
GRANT SELECT ON TABLE public.pivovary TO jnovak;
GRANT SELECT ON TABLE public.pivovary TO pdvorakova;
GRANT SELECT ON TABLE public.pivovary TO ksvoboda;
GRANT SELECT ON TABLE public.pivovary TO anovotna;
GRANT SELECT ON TABLE public.pivovary TO pmaly;
          public          postgres    false    216            �            1259    25328    agregatni_funkce_a_having    VIEW     $  CREATE VIEW public.agregatni_funkce_a_having AS
 SELECT pivovary.nazev,
    count(piva.pivoid) AS count
   FROM (public.pivovary
     JOIN public.piva ON ((pivovary.pivovarid = piva.pivovarid)))
  GROUP BY pivovary.nazev
 HAVING (count(piva.pivoid) > 2)
  ORDER BY (count(piva.pivoid)) DESC;
 ,   DROP VIEW public.agregatni_funkce_a_having;
       public          postgres    false    216    220    220    216            �            1259    41764 	   audit_log    TABLE     Z  CREATE TABLE public.audit_log (
    logid integer NOT NULL,
    tabulka character varying(255),
    akce character varying(10),
    pivoid integer,
    predchozi_hodnota character varying(255),
    nova_hodnota character varying(255),
    datum_cas timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    "uživatel" character varying(255)
);
    DROP TABLE public.audit_log;
       public         heap    postgres    false            �            1259    41763    audit_log_logid_seq    SEQUENCE     �   CREATE SEQUENCE public.audit_log_logid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.audit_log_logid_seq;
       public          postgres    false    235            �           0    0    audit_log_logid_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.audit_log_logid_seq OWNED BY public.audit_log.logid;
          public          postgres    false    234            �            1259    25291    recenze    TABLE     �   CREATE TABLE public.recenze (
    recenzeid integer NOT NULL,
    pivoid integer,
    uzivatelid integer,
    hodnoceni integer,
    komentar text,
    CONSTRAINT recenze_hodnoceni_check CHECK (((hodnoceni >= 1) AND (hodnoceni <= 5)))
);
    DROP TABLE public.recenze;
       public         heap    postgres    false            �            1259    25324 	   left_join    VIEW     �   CREATE VIEW public.left_join AS
 SELECT piva.nazev,
    recenze.komentar
   FROM (public.piva
     LEFT JOIN public.recenze ON ((piva.pivoid = recenze.pivoid)));
    DROP VIEW public.left_join;
       public          postgres    false    227    220    220    227            �            1259    25262    nutricni_hodnoty    TABLE     �   CREATE TABLE public.nutricni_hodnoty (
    pivoid integer NOT NULL,
    zivinaid integer NOT NULL,
    mnozstvi numeric(10,2)
);
 $   DROP TABLE public.nutricni_hodnoty;
       public         heap    postgres    false            �            1259    25238    piva_pivoid_seq    SEQUENCE     �   CREATE SEQUENCE public.piva_pivoid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.piva_pivoid_seq;
       public          postgres    false    220            �           0    0    piva_pivoid_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.piva_pivoid_seq OWNED BY public.piva.pivoid;
          public          postgres    false    219            �            1259    25222    pivovary_pivovarid_seq    SEQUENCE     �   CREATE SEQUENCE public.pivovary_pivovarid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.pivovary_pivovarid_seq;
       public          postgres    false    216            �           0    0    pivovary_pivovarid_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.pivovary_pivovarid_seq OWNED BY public.pivovary.pivovarid;
          public          postgres    false    215            �            1259    41893    prehled_piv    VIEW     g  CREATE VIEW public.prehled_piv AS
 SELECT p.nazev AS nazev_piva,
    pv.nazev AS nazev_pivovaru,
    avg(r.hodnoceni) AS prumerne_hodnoceni,
    count(r.recenzeid) AS pocet_recenzi
   FROM ((public.piva p
     JOIN public.pivovary pv ON ((p.pivovarid = pv.pivovarid)))
     LEFT JOIN public.recenze r ON ((p.pivoid = r.pivoid)))
  GROUP BY p.nazev, pv.nazev;
    DROP VIEW public.prehled_piv;
       public          postgres    false    216    216    220    220    220    227    227    227            �            1259    25290    recenze_recenzeid_seq    SEQUENCE     �   CREATE SEQUENCE public.recenze_recenzeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.recenze_recenzeid_seq;
       public          postgres    false    227            �           0    0    recenze_recenzeid_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.recenze_recenzeid_seq OWNED BY public.recenze.recenzeid;
          public          postgres    false    226            �            1259    41776    sklad    TABLE     �   CREATE TABLE public.sklad (
    skladid integer NOT NULL,
    pivovarid integer NOT NULL,
    surovina character varying(50) NOT NULL,
    mnozstvi numeric(10,2) NOT NULL,
    jednotka character varying(20) NOT NULL,
    datum_posledni_dodavky date
);
    DROP TABLE public.sklad;
       public         heap    postgres    false            �           0    0    TABLE sklad    ACL       GRANT SELECT ON TABLE public.sklad TO jnovak;
GRANT SELECT ON TABLE public.sklad TO anovotna;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad TO pdvorakova;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad TO pmaly;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad TO skladadmin;
          public          postgres    false    237            �            1259    41812 	   sklad_log    TABLE     =  CREATE TABLE public.sklad_log (
    logid integer NOT NULL,
    cas_zmeny timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    akce character varying(10) NOT NULL,
    surovina character varying(255) NOT NULL,
    skladid integer NOT NULL,
    puvodni_mnozstvi numeric(10,2),
    nove_mnozstvi numeric(10,2)
);
    DROP TABLE public.sklad_log;
       public         heap    postgres    false            �           0    0    TABLE sklad_log    ACL     -  GRANT SELECT ON TABLE public.sklad_log TO anovotna;
GRANT SELECT ON TABLE public.sklad_log TO jnovak;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad_log TO pdvorakova;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad_log TO pmaly;
GRANT SELECT,INSERT,UPDATE ON TABLE public.sklad_log TO skladadmin;
          public          postgres    false    239            �            1259    41811    sklad_log_logid_seq    SEQUENCE     �   CREATE SEQUENCE public.sklad_log_logid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.sklad_log_logid_seq;
       public          postgres    false    239            �           0    0    sklad_log_logid_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.sklad_log_logid_seq OWNED BY public.sklad_log.logid;
          public          postgres    false    238            �           0    0    SEQUENCE sklad_log_logid_seq    ACL     �   GRANT ALL ON SEQUENCE public.sklad_log_logid_seq TO skladadmin;
GRANT ALL ON SEQUENCE public.sklad_log_logid_seq TO pdvorakova;
GRANT ALL ON SEQUENCE public.sklad_log_logid_seq TO pmaly;
          public          postgres    false    238            �            1259    41775    sklad_skladid_seq    SEQUENCE     �   CREATE SEQUENCE public.sklad_skladid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.sklad_skladid_seq;
       public          postgres    false    237            �           0    0    sklad_skladid_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.sklad_skladid_seq OWNED BY public.sklad.skladid;
          public          postgres    false    236            �           0    0    SEQUENCE sklad_skladid_seq    ACL     �   GRANT ALL ON SEQUENCE public.sklad_skladid_seq TO pdvorakova;
GRANT ALL ON SEQUENCE public.sklad_skladid_seq TO skladadmin;
GRANT ALL ON SEQUENCE public.sklad_skladid_seq TO pmaly;
          public          postgres    false    236            �            1259    25232    typy    TABLE     d   CREATE TABLE public.typy (
    typid integer NOT NULL,
    nazev character varying(255) NOT NULL
);
    DROP TABLE public.typy;
       public         heap    postgres    false            �            1259    25231    typy_typid_seq    SEQUENCE     �   CREATE SEQUENCE public.typy_typid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.typy_typid_seq;
       public          postgres    false    218            �           0    0    typy_typid_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.typy_typid_seq OWNED BY public.typy.typid;
          public          postgres    false    217            �            1259    25311    udalosti    TABLE     �   CREATE TABLE public.udalosti (
    udalostid integer NOT NULL,
    nazev character varying(255) NOT NULL,
    lokace character varying(255),
    datum date,
    cas character varying(5),
    pivovarid integer
);
    DROP TABLE public.udalosti;
       public         heap    postgres    false            �            1259    25310    udalosti_udalostid_seq    SEQUENCE     �   CREATE SEQUENCE public.udalosti_udalostid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.udalosti_udalostid_seq;
       public          postgres    false    229            �           0    0    udalosti_udalostid_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.udalosti_udalostid_seq OWNED BY public.udalosti.udalostid;
          public          postgres    false    228            �            1259    25278 	   uzivatele    TABLE     �   CREATE TABLE public.uzivatele (
    uzivatelid integer NOT NULL,
    uzivatelske_jmeno character varying(255) NOT NULL,
    email character varying(255) NOT NULL
);
    DROP TABLE public.uzivatele;
       public         heap    postgres    false            �            1259    25277    uzivatele_uzivatelid_seq    SEQUENCE     �   CREATE SEQUENCE public.uzivatele_uzivatelid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.uzivatele_uzivatelid_seq;
       public          postgres    false    225            �           0    0    uzivatele_uzivatelid_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.uzivatele_uzivatelid_seq OWNED BY public.uzivatele.uzivatelid;
          public          postgres    false    224            �            1259    41741    zamestnanci    TABLE     I  CREATE TABLE public.zamestnanci (
    zamestnanecid integer NOT NULL,
    jmeno_a_prijmeni character varying(255) NOT NULL,
    pozice character varying(100) NOT NULL,
    uzivatelske_jmeno character varying(100) NOT NULL,
    heslo character varying(100) NOT NULL,
    pivovarid integer NOT NULL,
    nadrizena_osoba integer
);
    DROP TABLE public.zamestnanci;
       public         heap    postgres    false            �           0    0    TABLE zamestnanci    ACL     C  GRANT SELECT ON TABLE public.zamestnanci TO skladadmin;
GRANT SELECT ON TABLE public.zamestnanci TO jnovak;
GRANT SELECT ON TABLE public.zamestnanci TO pdvorakova;
GRANT SELECT ON TABLE public.zamestnanci TO ksvoboda;
GRANT SELECT ON TABLE public.zamestnanci TO anovotna;
GRANT SELECT ON TABLE public.zamestnanci TO pmaly;
          public          postgres    false    233            �            1259    41740    zamestnanci_zamestnanecid_seq    SEQUENCE     �   CREATE SEQUENCE public.zamestnanci_zamestnanecid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.zamestnanci_zamestnanecid_seq;
       public          postgres    false    233            �           0    0    zamestnanci_zamestnanecid_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE public.zamestnanci_zamestnanecid_seq OWNED BY public.zamestnanci.zamestnanecid;
          public          postgres    false    232            �            1259    25256    ziviny    TABLE     i   CREATE TABLE public.ziviny (
    zivinaid integer NOT NULL,
    nazev character varying(255) NOT NULL
);
    DROP TABLE public.ziviny;
       public         heap    postgres    false            �            1259    25255    ziviny_zivinaid_seq    SEQUENCE     �   CREATE SEQUENCE public.ziviny_zivinaid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.ziviny_zivinaid_seq;
       public          postgres    false    222            �           0    0    ziviny_zivinaid_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.ziviny_zivinaid_seq OWNED BY public.ziviny.zivinaid;
          public          postgres    false    221            �           2604    41767    audit_log logid    DEFAULT     r   ALTER TABLE ONLY public.audit_log ALTER COLUMN logid SET DEFAULT nextval('public.audit_log_logid_seq'::regclass);
 >   ALTER TABLE public.audit_log ALTER COLUMN logid DROP DEFAULT;
       public          postgres    false    234    235    235            �           2604    25242    piva pivoid    DEFAULT     j   ALTER TABLE ONLY public.piva ALTER COLUMN pivoid SET DEFAULT nextval('public.piva_pivoid_seq'::regclass);
 :   ALTER TABLE public.piva ALTER COLUMN pivoid DROP DEFAULT;
       public          postgres    false    220    219    220            �           2604    25226    pivovary pivovarid    DEFAULT     x   ALTER TABLE ONLY public.pivovary ALTER COLUMN pivovarid SET DEFAULT nextval('public.pivovary_pivovarid_seq'::regclass);
 A   ALTER TABLE public.pivovary ALTER COLUMN pivovarid DROP DEFAULT;
       public          postgres    false    215    216    216            �           2604    25294    recenze recenzeid    DEFAULT     v   ALTER TABLE ONLY public.recenze ALTER COLUMN recenzeid SET DEFAULT nextval('public.recenze_recenzeid_seq'::regclass);
 @   ALTER TABLE public.recenze ALTER COLUMN recenzeid DROP DEFAULT;
       public          postgres    false    227    226    227            �           2604    41779    sklad skladid    DEFAULT     n   ALTER TABLE ONLY public.sklad ALTER COLUMN skladid SET DEFAULT nextval('public.sklad_skladid_seq'::regclass);
 <   ALTER TABLE public.sklad ALTER COLUMN skladid DROP DEFAULT;
       public          postgres    false    236    237    237            �           2604    41815    sklad_log logid    DEFAULT     r   ALTER TABLE ONLY public.sklad_log ALTER COLUMN logid SET DEFAULT nextval('public.sklad_log_logid_seq'::regclass);
 >   ALTER TABLE public.sklad_log ALTER COLUMN logid DROP DEFAULT;
       public          postgres    false    239    238    239            �           2604    25235 
   typy typid    DEFAULT     h   ALTER TABLE ONLY public.typy ALTER COLUMN typid SET DEFAULT nextval('public.typy_typid_seq'::regclass);
 9   ALTER TABLE public.typy ALTER COLUMN typid DROP DEFAULT;
       public          postgres    false    217    218    218            �           2604    25314    udalosti udalostid    DEFAULT     x   ALTER TABLE ONLY public.udalosti ALTER COLUMN udalostid SET DEFAULT nextval('public.udalosti_udalostid_seq'::regclass);
 A   ALTER TABLE public.udalosti ALTER COLUMN udalostid DROP DEFAULT;
       public          postgres    false    228    229    229            �           2604    25281    uzivatele uzivatelid    DEFAULT     |   ALTER TABLE ONLY public.uzivatele ALTER COLUMN uzivatelid SET DEFAULT nextval('public.uzivatele_uzivatelid_seq'::regclass);
 C   ALTER TABLE public.uzivatele ALTER COLUMN uzivatelid DROP DEFAULT;
       public          postgres    false    224    225    225            �           2604    41744    zamestnanci zamestnanecid    DEFAULT     �   ALTER TABLE ONLY public.zamestnanci ALTER COLUMN zamestnanecid SET DEFAULT nextval('public.zamestnanci_zamestnanecid_seq'::regclass);
 H   ALTER TABLE public.zamestnanci ALTER COLUMN zamestnanecid DROP DEFAULT;
       public          postgres    false    232    233    233            �           2604    25259    ziviny zivinaid    DEFAULT     r   ALTER TABLE ONLY public.ziviny ALTER COLUMN zivinaid SET DEFAULT nextval('public.ziviny_zivinaid_seq'::regclass);
 >   ALTER TABLE public.ziviny ALTER COLUMN zivinaid DROP DEFAULT;
       public          postgres    false    221    222    222            �          0    41764 	   audit_log 
   TABLE DATA           z   COPY public.audit_log (logid, tabulka, akce, pivoid, predchozi_hodnota, nova_hodnota, datum_cas, "uživatel") FROM stdin;
    public          postgres    false    235   g�       �          0    25262    nutricni_hodnoty 
   TABLE DATA           F   COPY public.nutricni_hodnoty (pivoid, zivinaid, mnozstvi) FROM stdin;
    public          postgres    false    223   �                 0    25239    piva 
   TABLE DATA           I   COPY public.piva (pivoid, nazev, typid, abv, ibu, pivovarid) FROM stdin;
    public          postgres    false    220   q�       {          0    25223    pivovary 
   TABLE DATA           E   COPY public.pivovary (pivovarid, nazev, lokace, zalozen) FROM stdin;
    public          postgres    false    216   ڷ       �          0    25291    recenze 
   TABLE DATA           U   COPY public.recenze (recenzeid, pivoid, uzivatelid, hodnoceni, komentar) FROM stdin;
    public          postgres    false    227   ��       �          0    41776    sklad 
   TABLE DATA           i   COPY public.sklad (skladid, pivovarid, surovina, mnozstvi, jednotka, datum_posledni_dodavky) FROM stdin;
    public          postgres    false    237   g�       �          0    41812 	   sklad_log 
   TABLE DATA           o   COPY public.sklad_log (logid, cas_zmeny, akce, surovina, skladid, puvodni_mnozstvi, nove_mnozstvi) FROM stdin;
    public          postgres    false    239   ��       }          0    25232    typy 
   TABLE DATA           ,   COPY public.typy (typid, nazev) FROM stdin;
    public          postgres    false    218   �       �          0    25311    udalosti 
   TABLE DATA           S   COPY public.udalosti (udalostid, nazev, lokace, datum, cas, pivovarid) FROM stdin;
    public          postgres    false    229   {�       �          0    25278 	   uzivatele 
   TABLE DATA           I   COPY public.uzivatele (uzivatelid, uzivatelske_jmeno, email) FROM stdin;
    public          postgres    false    225   ��       �          0    41741    zamestnanci 
   TABLE DATA           �   COPY public.zamestnanci (zamestnanecid, jmeno_a_prijmeni, pozice, uzivatelske_jmeno, heslo, pivovarid, nadrizena_osoba) FROM stdin;
    public          postgres    false    233   &�       �          0    25256    ziviny 
   TABLE DATA           1   COPY public.ziviny (zivinaid, nazev) FROM stdin;
    public          postgres    false    222   5�       �           0    0    audit_log_logid_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.audit_log_logid_seq', 4, true);
          public          postgres    false    234            �           0    0    piva_pivoid_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.piva_pivoid_seq', 51, true);
          public          postgres    false    219            �           0    0    pivovary_pivovarid_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.pivovary_pivovarid_seq', 20, true);
          public          postgres    false    215            �           0    0    recenze_recenzeid_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.recenze_recenzeid_seq', 20, true);
          public          postgres    false    226            �           0    0    sklad_log_logid_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.sklad_log_logid_seq', 20, true);
          public          postgres    false    238            �           0    0    sklad_skladid_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.sklad_skladid_seq', 12, true);
          public          postgres    false    236            �           0    0    typy_typid_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.typy_typid_seq', 4, true);
          public          postgres    false    217            �           0    0    udalosti_udalostid_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.udalosti_udalostid_seq', 20, true);
          public          postgres    false    228            �           0    0    uzivatele_uzivatelid_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.uzivatele_uzivatelid_seq', 20, true);
          public          postgres    false    224            �           0    0    zamestnanci_zamestnanecid_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.zamestnanci_zamestnanecid_seq', 7, true);
          public          postgres    false    232            �           0    0    ziviny_zivinaid_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.ziviny_zivinaid_seq', 4, true);
          public          postgres    false    221            �           2606    41772    audit_log audit_log_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (logid);
 B   ALTER TABLE ONLY public.audit_log DROP CONSTRAINT audit_log_pkey;
       public            postgres    false    235            �           2606    25266 &   nutricni_hodnoty nutricni_hodnoty_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY public.nutricni_hodnoty
    ADD CONSTRAINT nutricni_hodnoty_pkey PRIMARY KEY (pivoid, zivinaid);
 P   ALTER TABLE ONLY public.nutricni_hodnoty DROP CONSTRAINT nutricni_hodnoty_pkey;
       public            postgres    false    223    223            �           2606    25244    piva piva_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY public.piva
    ADD CONSTRAINT piva_pkey PRIMARY KEY (pivoid);
 8   ALTER TABLE ONLY public.piva DROP CONSTRAINT piva_pkey;
       public            postgres    false    220            �           2606    25230    pivovary pivovary_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.pivovary
    ADD CONSTRAINT pivovary_pkey PRIMARY KEY (pivovarid);
 @   ALTER TABLE ONLY public.pivovary DROP CONSTRAINT pivovary_pkey;
       public            postgres    false    216            �           2606    25299    recenze recenze_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.recenze
    ADD CONSTRAINT recenze_pkey PRIMARY KEY (recenzeid);
 >   ALTER TABLE ONLY public.recenze DROP CONSTRAINT recenze_pkey;
       public            postgres    false    227            �           2606    41818    sklad_log sklad_log_pkey 
   CONSTRAINT     Y   ALTER TABLE ONLY public.sklad_log
    ADD CONSTRAINT sklad_log_pkey PRIMARY KEY (logid);
 B   ALTER TABLE ONLY public.sklad_log DROP CONSTRAINT sklad_log_pkey;
       public            postgres    false    239            �           2606    41781    sklad sklad_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.sklad
    ADD CONSTRAINT sklad_pkey PRIMARY KEY (skladid);
 :   ALTER TABLE ONLY public.sklad DROP CONSTRAINT sklad_pkey;
       public            postgres    false    237            �           2606    25237    typy typy_pkey 
   CONSTRAINT     O   ALTER TABLE ONLY public.typy
    ADD CONSTRAINT typy_pkey PRIMARY KEY (typid);
 8   ALTER TABLE ONLY public.typy DROP CONSTRAINT typy_pkey;
       public            postgres    false    218            �           2606    25318    udalosti udalosti_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY public.udalosti
    ADD CONSTRAINT udalosti_pkey PRIMARY KEY (udalostid);
 @   ALTER TABLE ONLY public.udalosti DROP CONSTRAINT udalosti_pkey;
       public            postgres    false    229            �           2606    25289    uzivatele uzivatele_email_key 
   CONSTRAINT     Y   ALTER TABLE ONLY public.uzivatele
    ADD CONSTRAINT uzivatele_email_key UNIQUE (email);
 G   ALTER TABLE ONLY public.uzivatele DROP CONSTRAINT uzivatele_email_key;
       public            postgres    false    225            �           2606    25285    uzivatele uzivatele_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public.uzivatele
    ADD CONSTRAINT uzivatele_pkey PRIMARY KEY (uzivatelid);
 B   ALTER TABLE ONLY public.uzivatele DROP CONSTRAINT uzivatele_pkey;
       public            postgres    false    225            �           2606    25287 )   uzivatele uzivatele_uzivatelske_nazev_key 
   CONSTRAINT     q   ALTER TABLE ONLY public.uzivatele
    ADD CONSTRAINT uzivatele_uzivatelske_nazev_key UNIQUE (uzivatelske_jmeno);
 S   ALTER TABLE ONLY public.uzivatele DROP CONSTRAINT uzivatele_uzivatelske_nazev_key;
       public            postgres    false    225            �           2606    41748    zamestnanci zamestnanci_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_pkey PRIMARY KEY (zamestnanecid);
 F   ALTER TABLE ONLY public.zamestnanci DROP CONSTRAINT zamestnanci_pkey;
       public            postgres    false    233            �           2606    41750 -   zamestnanci zamestnanci_uzivatelske_jmeno_key 
   CONSTRAINT     u   ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_uzivatelske_jmeno_key UNIQUE (uzivatelske_jmeno);
 W   ALTER TABLE ONLY public.zamestnanci DROP CONSTRAINT zamestnanci_uzivatelske_jmeno_key;
       public            postgres    false    233            �           2606    25261    ziviny ziviny_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.ziviny
    ADD CONSTRAINT ziviny_pkey PRIMARY KEY (zivinaid);
 <   ALTER TABLE ONLY public.ziviny DROP CONSTRAINT ziviny_pkey;
       public            postgres    false    222            �           1259    41735    idx_uzivatele_email    INDEX     Q   CREATE UNIQUE INDEX idx_uzivatele_email ON public.uzivatele USING btree (email);
 '   DROP INDEX public.idx_uzivatele_email;
       public            postgres    false    225            �           1259    41826    sklad_surovina_pivovarid_idx    INDEX     d   CREATE UNIQUE INDEX sklad_surovina_pivovarid_idx ON public.sklad USING btree (surovina, pivovarid);
 0   DROP INDEX public.sklad_surovina_pivovarid_idx;
       public            postgres    false    237    237            �           2620    41774    piva trg_auditpivaupdate    TRIGGER     w   CREATE TRIGGER trg_auditpivaupdate AFTER UPDATE ON public.piva FOR EACH ROW EXECUTE FUNCTION public.auditpivaupdate();
 1   DROP TRIGGER trg_auditpivaupdate ON public.piva;
       public          postgres    false    220    246            �           2620    41825    sklad trg_skladlog    TRIGGER     �   CREATE TRIGGER trg_skladlog AFTER INSERT OR DELETE OR UPDATE ON public.sklad FOR EACH ROW EXECUTE FUNCTION public.logskladchanges();
 +   DROP TRIGGER trg_skladlog ON public.sklad;
       public          postgres    false    247    237            �           2606    25267 -   nutricni_hodnoty nutricni_hodnoty_pivoid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.nutricni_hodnoty
    ADD CONSTRAINT nutricni_hodnoty_pivoid_fkey FOREIGN KEY (pivoid) REFERENCES public.piva(pivoid);
 W   ALTER TABLE ONLY public.nutricni_hodnoty DROP CONSTRAINT nutricni_hodnoty_pivoid_fkey;
       public          postgres    false    4780    223    220            �           2606    25272 /   nutricni_hodnoty nutricni_hodnoty_zivinaid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.nutricni_hodnoty
    ADD CONSTRAINT nutricni_hodnoty_zivinaid_fkey FOREIGN KEY (zivinaid) REFERENCES public.ziviny(zivinaid);
 Y   ALTER TABLE ONLY public.nutricni_hodnoty DROP CONSTRAINT nutricni_hodnoty_zivinaid_fkey;
       public          postgres    false    222    4782    223            �           2606    25245    piva piva_pivovarid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.piva
    ADD CONSTRAINT piva_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid);
 B   ALTER TABLE ONLY public.piva DROP CONSTRAINT piva_pivovarid_fkey;
       public          postgres    false    220    4776    216            �           2606    25250    piva piva_typid_fkey    FK CONSTRAINT     s   ALTER TABLE ONLY public.piva
    ADD CONSTRAINT piva_typid_fkey FOREIGN KEY (typid) REFERENCES public.typy(typid);
 >   ALTER TABLE ONLY public.piva DROP CONSTRAINT piva_typid_fkey;
       public          postgres    false    218    220    4778            �           2606    25300    recenze recenze_pivoid_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.recenze
    ADD CONSTRAINT recenze_pivoid_fkey FOREIGN KEY (pivoid) REFERENCES public.piva(pivoid);
 E   ALTER TABLE ONLY public.recenze DROP CONSTRAINT recenze_pivoid_fkey;
       public          postgres    false    227    220    4780            �           2606    25305    recenze recenze_uzivatelid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.recenze
    ADD CONSTRAINT recenze_uzivatelid_fkey FOREIGN KEY (uzivatelid) REFERENCES public.uzivatele(uzivatelid);
 I   ALTER TABLE ONLY public.recenze DROP CONSTRAINT recenze_uzivatelid_fkey;
       public          postgres    false    4789    225    227            �           2606    41819     sklad_log sklad_log_skladid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sklad_log
    ADD CONSTRAINT sklad_log_skladid_fkey FOREIGN KEY (skladid) REFERENCES public.sklad(skladid);
 J   ALTER TABLE ONLY public.sklad_log DROP CONSTRAINT sklad_log_skladid_fkey;
       public          postgres    false    239    237    4803            �           2606    41782    sklad sklad_pivovarid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.sklad
    ADD CONSTRAINT sklad_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid) ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.sklad DROP CONSTRAINT sklad_pivovarid_fkey;
       public          postgres    false    237    216    4776            �           2606    25319     udalosti udalosti_pivovarid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.udalosti
    ADD CONSTRAINT udalosti_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid);
 J   ALTER TABLE ONLY public.udalosti DROP CONSTRAINT udalosti_pivovarid_fkey;
       public          postgres    false    4776    229    216            �           2606    41756 ,   zamestnanci zamestnanci_nadrizena_osoba_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_nadrizena_osoba_fkey FOREIGN KEY (nadrizena_osoba) REFERENCES public.zamestnanci(zamestnanecid);
 V   ALTER TABLE ONLY public.zamestnanci DROP CONSTRAINT zamestnanci_nadrizena_osoba_fkey;
       public          postgres    false    233    233    4797            �           2606    41751 &   zamestnanci zamestnanci_pivovarid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.zamestnanci
    ADD CONSTRAINT zamestnanci_pivovarid_fkey FOREIGN KEY (pivovarid) REFERENCES public.pivovary(pivovarid);
 P   ALTER TABLE ONLY public.zamestnanci DROP CONSTRAINT zamestnanci_pivovarid_fkey;
       public          postgres    false    216    233    4776            h           3256    41861    sklad manager_1_sklad    POLICY     _   CREATE POLICY manager_1_sklad ON public.sklad FOR SELECT TO manager_1 USING ((pivovarid = 1));
 -   DROP POLICY manager_1_sklad ON public.sklad;
       public          postgres    false    237    237            i           3256    41862    sklad_log manager_1_sklad_log    POLICY     e   CREATE POLICY manager_1_sklad_log ON public.sklad_log FOR SELECT TO manager_1 USING ((skladid = 1));
 5   DROP POLICY manager_1_sklad_log ON public.sklad_log;
       public          postgres    false    239    239            j           3256    41865    sklad manager_2_sklad    POLICY     _   CREATE POLICY manager_2_sklad ON public.sklad FOR SELECT TO manager_2 USING ((pivovarid = 2));
 -   DROP POLICY manager_2_sklad ON public.sklad;
       public          postgres    false    237    237            k           3256    41866    sklad_log manager_2_sklad_log    POLICY     e   CREATE POLICY manager_2_sklad_log ON public.sklad_log FOR SELECT TO manager_2 USING ((skladid = 5));
 5   DROP POLICY manager_2_sklad_log ON public.sklad_log;
       public          postgres    false    239    239            f           0    41776    sklad    ROW SECURITY     3   ALTER TABLE public.sklad ENABLE ROW LEVEL SECURITY;          public          postgres    false    237            g           0    41812 	   sklad_log    ROW SECURITY     7   ALTER TABLE public.sklad_log ENABLE ROW LEVEL SECURITY;          public          postgres    false    239            n           3256    41871    sklad sladek_1_sklad_insert    POLICY     i   CREATE POLICY sladek_1_sklad_insert ON public.sklad FOR INSERT TO sladek_1 WITH CHECK ((pivovarid = 1));
 3   DROP POLICY sladek_1_sklad_insert ON public.sklad;
       public          postgres    false    237    237            o           3256    41872    sklad_log sladek_1_sklad_log    POLICY     c   CREATE POLICY sladek_1_sklad_log ON public.sklad_log FOR SELECT TO sladek_1 USING ((skladid = 1));
 4   DROP POLICY sladek_1_sklad_log ON public.sklad_log;
       public          postgres    false    239    239            p           3256    41873 #   sklad_log sladek_1_sklad_log_insert    POLICY     o   CREATE POLICY sladek_1_sklad_log_insert ON public.sklad_log FOR INSERT TO sladek_1 WITH CHECK ((skladid = 1));
 ;   DROP POLICY sladek_1_sklad_log_insert ON public.sklad_log;
       public          postgres    false    239    239            q           3256    41874 #   sklad_log sladek_1_sklad_log_update    POLICY     j   CREATE POLICY sladek_1_sklad_log_update ON public.sklad_log FOR UPDATE TO sladek_1 USING ((skladid = 1));
 ;   DROP POLICY sladek_1_sklad_log_update ON public.sklad_log;
       public          postgres    false    239    239            l           3256    41869    sklad sladek_1_sklad_select    POLICY     d   CREATE POLICY sladek_1_sklad_select ON public.sklad FOR SELECT TO sladek_1 USING ((pivovarid = 1));
 3   DROP POLICY sladek_1_sklad_select ON public.sklad;
       public          postgres    false    237    237            m           3256    41870    sklad sladek_1_sklad_update    POLICY     d   CREATE POLICY sladek_1_sklad_update ON public.sklad FOR UPDATE TO sladek_1 USING ((pivovarid = 1));
 3   DROP POLICY sladek_1_sklad_update ON public.sklad;
       public          postgres    false    237    237            s           3256    41878    sklad sladek_2_sklad_insert    POLICY     i   CREATE POLICY sladek_2_sklad_insert ON public.sklad FOR INSERT TO sladek_2 WITH CHECK ((pivovarid = 2));
 3   DROP POLICY sladek_2_sklad_insert ON public.sklad;
       public          postgres    false    237    237            u           3256    41880    sklad_log sladek_2_sklad_log    POLICY     c   CREATE POLICY sladek_2_sklad_log ON public.sklad_log FOR SELECT TO sladek_2 USING ((skladid = 5));
 4   DROP POLICY sladek_2_sklad_log ON public.sklad_log;
       public          postgres    false    239    239            v           3256    41881 #   sklad_log sladek_2_sklad_log_insert    POLICY     o   CREATE POLICY sladek_2_sklad_log_insert ON public.sklad_log FOR INSERT TO sladek_2 WITH CHECK ((skladid = 5));
 ;   DROP POLICY sladek_2_sklad_log_insert ON public.sklad_log;
       public          postgres    false    239    239            w           3256    41882 #   sklad_log sladek_2_sklad_log_update    POLICY     j   CREATE POLICY sladek_2_sklad_log_update ON public.sklad_log FOR UPDATE TO sladek_2 USING ((skladid = 5));
 ;   DROP POLICY sladek_2_sklad_log_update ON public.sklad_log;
       public          postgres    false    239    239            r           3256    41877    sklad sladek_2_sklad_select    POLICY     d   CREATE POLICY sladek_2_sklad_select ON public.sklad FOR SELECT TO sladek_2 USING ((pivovarid = 2));
 3   DROP POLICY sladek_2_sklad_select ON public.sklad;
       public          postgres    false    237    237            t           3256    41879    sklad sladek_2_sklad_update    POLICY     d   CREATE POLICY sladek_2_sklad_update ON public.sklad FOR UPDATE TO sladek_2 USING ((pivovarid = 2));
 3   DROP POLICY sladek_2_sklad_update ON public.sklad;
       public          postgres    false    237    237            x           3256    41890    sklad warehouse_manager_sklad    POLICY     Y   CREATE POLICY warehouse_manager_sklad ON public.sklad TO warehouse_manager USING (true);
 5   DROP POLICY warehouse_manager_sklad ON public.sklad;
       public          postgres    false    237            y           3256    41891 %   sklad_log warehouse_manager_sklad_log    POLICY     a   CREATE POLICY warehouse_manager_sklad_log ON public.sklad_log TO warehouse_manager USING (true);
 =   DROP POLICY warehouse_manager_sklad_log ON public.sklad_log;
       public          postgres    false    239            �   �   x���1
�0��99E/А���4��3���!�l���'�b��J�@@�������#�v��1XV̗��!ͷ#��^O��lA6������Mc��R�kj��bE�E�1J����U�S�e>��X��$m
F5�=�,[1���� 8�oցW�      �   P  x�E����0C�?�d���e��c妁7�F��O~��q�O~K��a%t3�nF�
�'J�/$�S�J�J�J֕,��:w o�7����7�4�lHW�й�}�7*�6�63�)��V@���Ў��Vu C�Щ$cS���ژ� N�A٠��P�l�4������)+V�W��'��.	��`�� ]���i�<yO�?-G�a��o�z��V����>F,<�|��D&��#��.�EV�:��Gݥ��ƨVT�~���T�6rg,J��>"}Q�S���E��W����h��#�/�L_��J_���$8k|G�i��4PS��4F91�}0rBW*0��^�/_�9���e?�/r�'T�l�Ơ��G�.3�`:�=��1�4�Z𼴧�9� �n�� �NL7��eV�4�$�Np^�l�� ��d��cq��ǃcL��6�ӱ���#{UsbLz��Ye+%���g�p��� �ep�7�}��liL���&4Ɯ_�tV��XS�c�qdW�1�fEK�D�1��o�f^����h4����ʘ W�QR6���s���:�q��gt��()���������-�         Y  x�u�Kn�0���)xC��� i��� i�ꆶ�X�,���6>C{���z�E�^�YT���z�v�0���?�G���S���b���M8	F�GDL8�ɵ��->u6]4;6.7*gW���*ovD � "h�<d� F �g��oJH��x��`�gطJ�1	�7
�_�K9S7rU��f�)�-�^m4����m{Y�,(��p�AE S���6�JC�����Z.U�Nժy����7��敚)(���q84�8LU�TheC�T[<���D�U�}����4������ٱ7��ʁ�>7���0.�~���X-�o���0.�����j��@"q��.��� 2�ԍ_�h��0��s���X��;��d�$�e���
� �y��(RN�T��@�>��~k�I���	A����sa��M8t�'弹_��cD.�����&�ɉF�V������̈�IfP��gY!���j����J=�P��[UZ�R�7�U%�+4�������ۚ^MJ���[��yY��Z����R��2�Q�k��/���b���Fr��R���qϮ���wu�2�t���]��ξBa�⎽V�G��kmk��h8��U�,�<������ֽ-�=��YU�fG9�az��~2ύ{5�F�K���"�b��fG�����#%G�֠�|�+m��D�説tV:9l7r@q�^������x�⚎�f��VJ���h8H7BC��%B���xb��\�M���9�1`p9Y�_�醝�`t��ԝ� q��v�A S�����/e��N��9��S�?칹N����B��S�o�	+Bx�,_�����Vyn+GC�vN?�(�Ƹ-c      {   �  x�]�Mn�0���S���Ȗ�u�V��DH� �aL�bL���'�O�E.t�e9BW��Ցa�qV���<~$������^����D�p�|�&,�Rw��)��F�۸N/|��,Kم�_�~���K�<�Y
7��uY��0�(�E%F�&����n���4eS��U��Q۶���i�2X�Лs�h��)ƻ�Ox�f���B����ʪQD���^qU7(Ƽ�8x��3�
aÐ�p��ܾ�4WhJ(�����8�W@�]7�S&�c1�`<@.�5�^-��Lf��^s[)<����pޑE����Щ��|��f��}�|(����Od�$��B�R�l����]V���Ѷ^92�t�@�n[�1��ʴk��0	��.ޞ���qp���$1��Vo�V�J'.�c���Q�h�G�Z�p���W�f��_�c��M      �   �  x�mSˎ�@<����#�y�^W+@,H+8q�ăl�=c�R�\�V���=D�����j[+ZEE���ꪚ@���:۫���l�dՔ��F�{�"i���D(�{m7�ki����?M��X��W��_��D�k3��p�2U��F�w��|z�b}U��1U�A�	v.����IRiJ�=��pR��=��	�e�s���m,�ԕr>}r�]R�*�-i[�E{c����tgbmɂ��L @i�r2j����hh�񽥘]�%����UM�T�ж���e�b�㚝I43�vG�nu�2�j��uȓ�6��#��,aU@:K�[�p)V��J9#]DCۨ�G��%o�66�%m�=��BS��tm�{b
���jZ!S�ʌ���8�D,+���s�bl�{m��ӵ-����:MƉ��`���Z��J�fr8^���Ե�٬����J�;���`jN�1�����^�J���S��+�XӲ��H��H��b�J��+85�6%�,���2T��o\b�Wfb��s����<�� I�G��B�4ѿa�k���)�9�TH*���A|�,DC��)O��6�NI�_��q���b>8C��'��ل�����y�2����(+��j2���8��CɅ�t#�%r �|ci�H��*�Y�y'v�Wl��|Β�������0��>      �   �   x�m��
�@�y��%��z	�zYl�B��"���V���<%���[��3U'R��Doፖ�K7���!}?��	�h���k�(}��#X�#H\� Z�0���f^��۴T�"���_�� ^p0�      �     x���1R�0��9�^`5��e[���h�����O�&Y�lҤz�׷�$,y�Cw��0bw�Hw7��W����1!�Ǉ��ރ+ܭ��V=�Y�<˲QZ�Y.Ç�vm�T�r�k��#�o�X�����Ｍ��fS�Ey����Y�*�s�۹�!�.N�U$��=C���F>�ct��LZJ1;Q�.ւgg��
ũcZ7.+w.ą����������eJ>��G\w�Ӎ���k֐Z����J#���\վ���,X8`�6Fe��/�U��>�0_�!�*      }   P   x�3�.;2�$��^��ԣ�/��2�	�T(;��HojA��
�e�\Ɯ!��e@	0τ�/51';?#?'39&���� �]#�      �   �  x�}U�n�F��_1�ŀC�ԣt�� kd�]�E�f$��#�XU�-b�He�b�b!_`7$_�3Ç�l����s���EU��})�F֊f�fmsHx�d��SwF���bN\��l'��K���X.�(ʸm��D@�y��Ik�Arמv�_��&q*���:�Y� Ys�9܊��d2�eQ�#>���g���'E*'W�����Lѯk�zb��	4�oy�ǡS�<�oy��eV՚~cd�p���E�p����ǲkz=�ȣ�mB���_�ft�E�	��X�$�]3��O6݃ܟC! �B���(�d����~j���ڠU��6(�6ݧ5ѕ���ۨ�8Z*�[�Z��p���Ԛq0�x�3l
-��Hnڧ����%�oU"�F�}��k;�va��y�j+D���h��^|���c�ly͡�}Q�I���T�S���Vk�#+kI�A(S��? �0 �Ó�NF*U@3~���^�`n;��0e=�5�Z��E�.G0�����gZ ݙ��K���Y&v/�>�^e��`M�d�һ�I�Сa}'\]��2��M.�����n2��j�o�����6��,��A�8��I�jh��L��"�la@��c�t��!̆U��.pi�,L�H�+�d� 7�H����Xab7�#�|�����눋�.�U���e�$3�Ҵ=:m���q2 ���ǳ�7N��QZE��F���wj$77���8���qF_����GȂ�7�ݓ�c���fl�9�^+q|<�0s=�Y�P�� v�m�I�aJ��+Uf��vCM��Q���\� ><��a��f��L#a�b�)�P�mO�2�g4��m��:�	�����5��U��Z��c��6��D*3���U�����M��(�!����Sʦ�p=�@_Xl�zS��e��,���Z$��>��rf�Eo�
u�ǸN���Y���8�:���*�K���zF�KL\4�	�Ώd��ȳ]t�_{z[���eY֖��      �   �  x�e�AN�0E��S����H JQ�R5�#5����Ԃ;� V= G`�p/<���=��F�v7���fW�
�v�<�W�kC:g�;���C�^����վ����d�e����"�"�? ��U@�͵�P
(ӣH���+�AM6�<��7t�ɣN�C�0�P=QE&bQ��R�)<�mv?;5E�|C�+mѼ%�3c�M<��m�˨tU^$�Q��q��E�d�םJ�ّd.�fg�8WH4�YfL�ׅS�;uT�Io}H=��M^�`Fv����яs�AF*�{�c�"S�	\�qޟC!E?=�,��1KpK>�,�=.�Tcd�K��R��Sxz�Jn��_AT^���,Na-k����>>�S1���Z��N?�<�c�w��ͻqU�ЎD��g���~nU#�      �   �   x�e�An� E��)8Ae;N���U�F�"e��Ġ63��������W����+`濙'jxB���`'��x�!N�8
��M:Mu���k��Fz��1��G�2[G!"��TC�x2�������Jͷ�$6�Sg����
��5{:��ka����Iޤm�Dє��h�j�U�E����Ӭأ�@ʴ˔j��MlG}?����(�P�2��Z������r��J��8:o����uO�����1ƾA�u      �   4   x�3�t:�6';�,3��ˈ3819#�(3��˘3�4��˄3����=... V)�     