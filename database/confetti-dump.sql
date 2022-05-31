--
-- PostgreSQL database dump
--

-- Dumped from database version 14.3
-- Dumped by pg_dump version 14.3

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
-- Name: confetti; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE confetti WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'en_US.utf8';


ALTER DATABASE confetti OWNER TO charly;

\connect confetti

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: addproduct(character varying, money); Type: PROCEDURE; Schema: public; Owner: charly
--

CREATE PROCEDURE public.addproduct(IN p_name character varying, IN p_unitprice money)
    LANGUAGE plpgsql
    AS $$
    begin
        insert into product values(default, p_name, default, p_unitprice);
    end
    $$;


ALTER PROCEDURE public.addproduct(IN p_name character varying, IN p_unitprice money) OWNER TO charly;

--
-- Name: addproductchange(integer, character, integer); Type: PROCEDURE; Schema: public; Owner: charly
--

CREATE PROCEDURE public.addproductchange(IN p_pid integer, IN p_type character, IN p_qty integer)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        insert into productChange values(default, p_pid, p_type, p_qty, default, default, default);
    end
    $$;


ALTER PROCEDURE public.addproductchange(IN p_pid integer, IN p_type character, IN p_qty integer) OWNER TO charly;

--
-- Name: addreservation(integer, integer, date); Type: PROCEDURE; Schema: public; Owner: charly
--

CREATE PROCEDURE public.addreservation(IN p_employeeid integer, IN p_clientid integer, IN p_eventdate date)
    LANGUAGE plpgsql
    AS $$
begin
    insert into reservation values(default, p_employeeid, p_clientid, p_eventdate, default, default, null);
end
$$;


ALTER PROCEDURE public.addreservation(IN p_employeeid integer, IN p_clientid integer, IN p_eventdate date) OWNER TO charly;

--
-- Name: addreservation(integer, integer, date, integer); Type: PROCEDURE; Schema: public; Owner: charly
--

CREATE PROCEDURE public.addreservation(IN p_employeeid integer, IN p_clientid integer, IN p_eventdate date, IN p_packageid integer)
    LANGUAGE plpgsql
    AS $$
begin
    insert into reservation values(default, p_employeeid, p_clientid, p_eventdate, default, default, p_packageid);
end
$$;


ALTER PROCEDURE public.addreservation(IN p_employeeid integer, IN p_clientid integer, IN p_eventdate date, IN p_packageid integer) OWNER TO charly;

--
-- Name: adduser(character varying, character varying, integer); Type: PROCEDURE; Schema: public; Owner: charly
--

CREATE PROCEDURE public.adduser(IN p_username character varying, IN p_password character varying, IN p_roleid integer)
    LANGUAGE plpgsql
    AS $_$
declare v_validUsername bool;
declare v_validPassword bool;
declare v_salt text;
begin
    -- Only word characters and digits, 1 to 255
    v_validUsername := (select p_username ~ '^[\d\w]{1,255}$');
    -- Minimum eight characters, at least one letter, one number and one special character
    v_validPassword := (select p_password ~ '^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,255}$');
    if exists(select username from employee where username = p_username) or not v_validPassword or not v_validUsername then
        return;
    end if;
    v_salt := gen_salt('bf', 8);
    insert into employee values(default, p_roleid, p_username, crypt(p_password, v_salt), v_salt);
end
$_$;


ALTER PROCEDURE public.adduser(IN p_username character varying, IN p_password character varying, IN p_roleid integer) OWNER TO charly;

--
-- Name: checkcredentials(character varying, character varying); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.checkcredentials(p_username character varying, p_password character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
declare v_hash text;
    declare v_salt text;
    declare v_validUsername bool;
    declare v_validPassword bool;
begin
    v_validUsername := exists(select p_username from employee where username = p_username);
    if not v_validUsername then
        return false;
    end if;
    select passwordhash, salt from employee where username=p_username into v_hash, v_salt;
    v_validPassword := (select v_hash = crypt(p_password, v_salt));
    if v_validPassword then
        return true;
    end if;
    return false;
end
$$;


ALTER FUNCTION public.checkcredentials(p_username character varying, p_password character varying) OWNER TO charly;

--
-- Name: tr_productchange_ai(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_productchange_ai() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare v_change integer;
    declare v_existence integer;
    BEGIN
        v_change := (select quantity from productChange where changeid = new.changeid);
        v_existence := (select existence from product where productid = new.productid);
        if new.type = 'S' or new.type = 'M' then
            v_change := v_change * -1;
        end if;
        update productChange set previousexistence = (v_existence - v_change) where changeId = new.changeId;
        update productChange set newexistence = (v_existence) where changeId = new.changeId;
        return new;
    end
$$;


ALTER FUNCTION public.tr_productchange_ai() OWNER TO charly;

--
-- Name: tr_productchange_bi(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_productchange_bi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare v_qty integer;
    begin
        v_qty := (select existence from product where productId = new.productId);
        if (new.type = 'S' or new.type = 'M') and v_qty - new.quantity < 0 then
            return null;
        end if;
        set new.previousamount = v_qty;
        if new.type = 'S' or new.type = 'M' then
            update product set existence = v_qty - new.quantity where productId = new.productId;
        else
            update product set existence = v_qty + new.quantity where productId = new.productId;
        end if;
        return new;
    end
$$;


ALTER FUNCTION public.tr_productchange_bi() OWNER TO charly;

--
-- Name: tr_reservation_bi(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_reservation_bi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    begin
        if exists (select reservationid from reservation where eventdate = new.eventdate) then
            select 'date already taken' as msg;
            return null;
        end if;
        return new;
    end
    $$;


ALTER FUNCTION public.tr_reservation_bi() OWNER TO charly;

--
-- Name: tr_reservation_service_ai(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_reservation_service_ai() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    declare v_currbalance money;
begin
    v_currbalance := (select balance from reservation where reservationid = new.reservationid);
    update reservation set balance = v_currbalance + (new.amount + (select price from service where serviceid = new.serviceid)) where reservationid = new.reservationid;
    return new;
end
$$;


ALTER FUNCTION public.tr_reservation_service_ai() OWNER TO charly;

--
-- Name: tr_reservationchange_ai(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_reservationchange_ai() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if new.type = 'R' then
        update reservation set eventDate = new.newdate where reservationid = new.reservationid;
    elseif new.type = 'C' then
        delete from reservation where reservationid = new.reservationid;
    end if;
    return new;
end
$$;


ALTER FUNCTION public.tr_reservationchange_ai() OWNER TO charly;

--
-- Name: tr_reservationchange_bi(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_reservationchange_bi() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    -- if type is reschedule and target date is taken AND still active, abort
    if new.type = 'R' and (select isactive from reservation where eventdate = new.newdate) is true then
        return null;
    end if;
    return new;
end
$$;


ALTER FUNCTION public.tr_reservationchange_bi() OWNER TO charly;

--
-- Name: tr_service_ai(); Type: FUNCTION; Schema: public; Owner: charly
--

CREATE FUNCTION public.tr_service_ai() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if (select new.productid is not null) then
        update service set price = (select unitprice from product where productid = new.productid) where serviceid = new.serviceid;
    end if;
    return new;
end
$$;


ALTER FUNCTION public.tr_service_ai() OWNER TO charly;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: client; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.client (
    clientid integer NOT NULL,
    firstname character varying(255) NOT NULL,
    lastname character varying(255) NOT NULL,
    phone character varying(255)
);


ALTER TABLE public.client OWNER TO charly;

--
-- Name: client_clientid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.client_clientid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.client_clientid_seq OWNER TO charly;

--
-- Name: client_clientid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.client_clientid_seq OWNED BY public.client.clientid;


--
-- Name: employee; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.employee (
    employeeid integer NOT NULL,
    roleid integer NOT NULL,
    username character varying(255) NOT NULL,
    passwordhash character varying(255) NOT NULL,
    salt character varying NOT NULL
);


ALTER TABLE public.employee OWNER TO charly;

--
-- Name: employee_employeeid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.employee_employeeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employee_employeeid_seq OWNER TO charly;

--
-- Name: employee_employeeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.employee_employeeid_seq OWNED BY public.employee.employeeid;


--
-- Name: package; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.package (
    packageid integer NOT NULL,
    name character varying(255) NOT NULL,
    description character varying(255) NOT NULL,
    price money NOT NULL
);


ALTER TABLE public.package OWNER TO charly;

--
-- Name: package_packageid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.package_packageid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.package_packageid_seq OWNER TO charly;

--
-- Name: package_packageid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.package_packageid_seq OWNED BY public.package.packageid;


--
-- Name: package_service; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.package_service (
    serviceid integer NOT NULL,
    packageid integer NOT NULL,
    amount integer NOT NULL
);


ALTER TABLE public.package_service OWNER TO charly;

--
-- Name: payment; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.payment (
    paymentid integer NOT NULL,
    reservationid integer NOT NULL,
    amount money NOT NULL,
    description character varying(255),
    date date DEFAULT now() NOT NULL
);


ALTER TABLE public.payment OWNER TO charly;

--
-- Name: payment_paymentid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.payment_paymentid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.payment_paymentid_seq OWNER TO charly;

--
-- Name: payment_paymentid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.payment_paymentid_seq OWNED BY public.payment.paymentid;


--
-- Name: product; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.product (
    productid integer NOT NULL,
    name character varying(255) NOT NULL,
    existence integer DEFAULT 0 NOT NULL,
    unitprice money NOT NULL
);


ALTER TABLE public.product OWNER TO charly;

--
-- Name: product_productid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.product_productid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.product_productid_seq OWNER TO charly;

--
-- Name: product_productid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.product_productid_seq OWNED BY public.product.productid;


--
-- Name: productchange; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.productchange (
    changeid integer NOT NULL,
    productid integer NOT NULL,
    type character(1) NOT NULL,
    quantity integer NOT NULL,
    previousexistence integer DEFAULT 0,
    newexistence integer DEFAULT 0 NOT NULL,
    date date DEFAULT now() NOT NULL
);


ALTER TABLE public.productchange OWNER TO charly;

--
-- Name: productchange_changeid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.productchange_changeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.productchange_changeid_seq OWNER TO charly;

--
-- Name: productchange_changeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.productchange_changeid_seq OWNED BY public.productchange.changeid;


--
-- Name: reservation; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.reservation (
    reservationid integer NOT NULL,
    employeeid integer NOT NULL,
    clientid integer NOT NULL,
    eventdate date NOT NULL,
    balance money DEFAULT 0.00,
    isactive boolean DEFAULT true,
    packageid integer
);


ALTER TABLE public.reservation OWNER TO charly;

--
-- Name: reservation_reservationid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.reservation_reservationid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reservation_reservationid_seq OWNER TO charly;

--
-- Name: reservation_reservationid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.reservation_reservationid_seq OWNED BY public.reservation.reservationid;


--
-- Name: reservation_service; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.reservation_service (
    reservationid integer NOT NULL,
    serviceid integer NOT NULL,
    amount integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.reservation_service OWNER TO charly;

--
-- Name: reservationchange; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.reservationchange (
    changeid integer NOT NULL,
    reservationid integer NOT NULL,
    type character(1),
    description character varying(255),
    date date DEFAULT now(),
    newdate date
);


ALTER TABLE public.reservationchange OWNER TO charly;

--
-- Name: reservationchange_changeid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.reservationchange_changeid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reservationchange_changeid_seq OWNER TO charly;

--
-- Name: reservationchange_changeid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.reservationchange_changeid_seq OWNED BY public.reservationchange.changeid;


--
-- Name: role; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.role (
    roleid integer NOT NULL,
    name character varying(255),
    salary money
);


ALTER TABLE public.role OWNER TO charly;

--
-- Name: role_roleid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.role_roleid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_roleid_seq OWNER TO charly;

--
-- Name: role_roleid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.role_roleid_seq OWNED BY public.role.roleid;


--
-- Name: service; Type: TABLE; Schema: public; Owner: charly
--

CREATE TABLE public.service (
    serviceid integer NOT NULL,
    name character varying(255) NOT NULL,
    price money DEFAULT (0)::money NOT NULL,
    description character varying(255) NOT NULL,
    productid integer
);


ALTER TABLE public.service OWNER TO charly;

--
-- Name: service_serviceid_seq; Type: SEQUENCE; Schema: public; Owner: charly
--

CREATE SEQUENCE public.service_serviceid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.service_serviceid_seq OWNER TO charly;

--
-- Name: service_serviceid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: charly
--

ALTER SEQUENCE public.service_serviceid_seq OWNED BY public.service.serviceid;


--
-- Name: client clientid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.client ALTER COLUMN clientid SET DEFAULT nextval('public.client_clientid_seq'::regclass);


--
-- Name: employee employeeid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.employee ALTER COLUMN employeeid SET DEFAULT nextval('public.employee_employeeid_seq'::regclass);


--
-- Name: package packageid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.package ALTER COLUMN packageid SET DEFAULT nextval('public.package_packageid_seq'::regclass);


--
-- Name: payment paymentid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.payment ALTER COLUMN paymentid SET DEFAULT nextval('public.payment_paymentid_seq'::regclass);


--
-- Name: product productid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.product ALTER COLUMN productid SET DEFAULT nextval('public.product_productid_seq'::regclass);


--
-- Name: productchange changeid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.productchange ALTER COLUMN changeid SET DEFAULT nextval('public.productchange_changeid_seq'::regclass);


--
-- Name: reservation reservationid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation ALTER COLUMN reservationid SET DEFAULT nextval('public.reservation_reservationid_seq'::regclass);


--
-- Name: reservationchange changeid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservationchange ALTER COLUMN changeid SET DEFAULT nextval('public.reservationchange_changeid_seq'::regclass);


--
-- Name: role roleid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.role ALTER COLUMN roleid SET DEFAULT nextval('public.role_roleid_seq'::regclass);


--
-- Name: service serviceid; Type: DEFAULT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.service ALTER COLUMN serviceid SET DEFAULT nextval('public.service_serviceid_seq'::regclass);


--
-- Data for Name: client; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.client (clientid, firstname, lastname, phone) FROM stdin;
1	John	Doe	\N
\.


--
-- Data for Name: employee; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.employee (employeeid, roleid, username, passwordhash, salt) FROM stdin;
8	1	charly	$2a$08$.5rhsErVt.8.osR2zUjtB.18zWU0xbBXa/T44o/dwpG7GIO/Qdi/q	$2a$08$.5rhsErVt.8.osR2zUjtB.
9	1	john1	$2a$08$F0VW/DlpPfVu8dDZ04P0ZevG4ba1.zoxc.oKYkDMIYSqIkFQGrCka	$2a$08$F0VW/DlpPfVu8dDZ04P0Ze
10	1	john2	$2a$08$ezIpzwcRQaIY9IQxK5d/yuttnP3ExQqpMJJyufv4MZUUPW7vYRlyi	$2a$08$ezIpzwcRQaIY9IQxK5d/yu
\.


--
-- Data for Name: package; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.package (packageid, name, description, price) FROM stdin;
\.


--
-- Data for Name: package_service; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.package_service (serviceid, packageid, amount) FROM stdin;
\.


--
-- Data for Name: payment; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.payment (paymentid, reservationid, amount, description, date) FROM stdin;
\.


--
-- Data for Name: product; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.product (productid, name, existence, unitprice) FROM stdin;
1	Coca-Cola	0	$10.00
\.


--
-- Data for Name: productchange; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.productchange (changeid, productid, type, quantity, previousexistence, newexistence, date) FROM stdin;
\.


--
-- Data for Name: reservation; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.reservation (reservationid, employeeid, clientid, eventdate, balance, isactive, packageid) FROM stdin;
1	8	1	2022-05-29	$0.00	t	\N
\.


--
-- Data for Name: reservation_service; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.reservation_service (reservationid, serviceid, amount) FROM stdin;
\.


--
-- Data for Name: reservationchange; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.reservationchange (changeid, reservationid, type, description, date, newdate) FROM stdin;
\.


--
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.role (roleid, name, salary) FROM stdin;
1	test	$10.00
\.


--
-- Data for Name: service; Type: TABLE DATA; Schema: public; Owner: charly
--

COPY public.service (serviceid, name, price, description, productid) FROM stdin;
\.


--
-- Name: client_clientid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.client_clientid_seq', 1, true);


--
-- Name: employee_employeeid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.employee_employeeid_seq', 10, true);


--
-- Name: package_packageid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.package_packageid_seq', 1, false);


--
-- Name: payment_paymentid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.payment_paymentid_seq', 1, false);


--
-- Name: product_productid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.product_productid_seq', 1, true);


--
-- Name: productchange_changeid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.productchange_changeid_seq', 19, true);


--
-- Name: reservation_reservationid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.reservation_reservationid_seq', 1, true);


--
-- Name: reservationchange_changeid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.reservationchange_changeid_seq', 1, false);


--
-- Name: role_roleid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.role_roleid_seq', 1, true);


--
-- Name: service_serviceid_seq; Type: SEQUENCE SET; Schema: public; Owner: charly
--

SELECT pg_catalog.setval('public.service_serviceid_seq', 1, false);


--
-- Name: client client_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.client
    ADD CONSTRAINT client_pkey PRIMARY KEY (clientid);


--
-- Name: employee employee_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employeeid);


--
-- Name: package package_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.package
    ADD CONSTRAINT package_pkey PRIMARY KEY (packageid);


--
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (paymentid);


--
-- Name: product product_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.product
    ADD CONSTRAINT product_pkey PRIMARY KEY (productid);


--
-- Name: productchange productchange_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.productchange
    ADD CONSTRAINT productchange_pkey PRIMARY KEY (changeid);


--
-- Name: reservation reservation_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (reservationid);


--
-- Name: reservationchange reservationchange_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservationchange
    ADD CONSTRAINT reservationchange_pkey PRIMARY KEY (changeid);


--
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (roleid);


--
-- Name: service service_pkey; Type: CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_pkey PRIMARY KEY (serviceid);


--
-- Name: reservation preventdeletion; Type: RULE; Schema: public; Owner: charly
--

CREATE RULE preventdeletion AS
    ON DELETE TO public.reservation DO INSTEAD NOTHING;


--
-- Name: productchange ai; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER ai AFTER INSERT ON public.productchange FOR EACH ROW EXECUTE FUNCTION public.tr_productchange_ai();


--
-- Name: reservation_service ai; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER ai AFTER INSERT ON public.reservation_service FOR EACH ROW EXECUTE FUNCTION public.tr_reservation_service_ai();


--
-- Name: reservationchange ai; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER ai AFTER INSERT ON public.reservationchange FOR EACH ROW EXECUTE FUNCTION public.tr_reservationchange_ai();


--
-- Name: service ai; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER ai AFTER INSERT ON public.service FOR EACH ROW EXECUTE FUNCTION public.tr_service_ai();


--
-- Name: productchange bi; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER bi BEFORE INSERT ON public.productchange FOR EACH ROW EXECUTE FUNCTION public.tr_productchange_bi();


--
-- Name: reservation bi; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER bi BEFORE INSERT ON public.reservation FOR EACH ROW EXECUTE FUNCTION public.tr_reservation_bi();


--
-- Name: reservationchange bi; Type: TRIGGER; Schema: public; Owner: charly
--

CREATE TRIGGER bi BEFORE INSERT ON public.reservationchange FOR EACH ROW EXECUTE FUNCTION public.tr_reservationchange_bi();


--
-- Name: employee employee_roleid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_roleid_fkey FOREIGN KEY (roleid) REFERENCES public.role(roleid);


--
-- Name: package_service package_service_packageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.package_service
    ADD CONSTRAINT package_service_packageid_fkey FOREIGN KEY (packageid) REFERENCES public.package(packageid);


--
-- Name: package_service package_service_serviceid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.package_service
    ADD CONSTRAINT package_service_serviceid_fkey FOREIGN KEY (serviceid) REFERENCES public.service(serviceid);


--
-- Name: payment payment_reservationid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_reservationid_fkey FOREIGN KEY (reservationid) REFERENCES public.reservation(reservationid);


--
-- Name: productchange productchange_productid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.productchange
    ADD CONSTRAINT productchange_productid_fkey FOREIGN KEY (productid) REFERENCES public.product(productid);


--
-- Name: reservation reservation_clientid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_clientid_fkey FOREIGN KEY (clientid) REFERENCES public.client(clientid);


--
-- Name: reservation reservation_employeeid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_employeeid_fkey FOREIGN KEY (employeeid) REFERENCES public.employee(employeeid);


--
-- Name: reservation reservation_packageid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_packageid_fkey FOREIGN KEY (packageid) REFERENCES public.package(packageid);


--
-- Name: reservation_service reservation_service_reservationid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation_service
    ADD CONSTRAINT reservation_service_reservationid_fkey FOREIGN KEY (reservationid) REFERENCES public.reservation(reservationid);


--
-- Name: reservation_service reservation_service_serviceid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservation_service
    ADD CONSTRAINT reservation_service_serviceid_fkey FOREIGN KEY (serviceid) REFERENCES public.service(serviceid);


--
-- Name: reservationchange reservationchange_reservationid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.reservationchange
    ADD CONSTRAINT reservationchange_reservationid_fkey FOREIGN KEY (reservationid) REFERENCES public.reservation(reservationid);


--
-- Name: service service_productid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: charly
--

ALTER TABLE ONLY public.service
    ADD CONSTRAINT service_productid_fkey FOREIGN KEY (productid) REFERENCES public.product(productid);


--
-- PostgreSQL database dump complete
--

