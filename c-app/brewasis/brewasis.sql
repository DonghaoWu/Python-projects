--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.19
-- Dumped by pg_dump version 9.5.19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: craft; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.craft (
    company text,
    state text,
    barrels2017 numeric(9,1),
    barrels2016 numeric(9,1),
    barrels2015 numeric(9,1),
    barrels2014 numeric(9,1),
    barrels2013 numeric(9,1),
    barrels2012 numeric(9,1),
    barrels2011 numeric(9,1),
    barrels2010 numeric(9,1),
    barrels2009 numeric(9,1),
    barrels2008 numeric(9,1)
);


--
-- Data for Name: craft; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.craft (company, state, barrels2017, barrels2016, barrels2015, barrels2014, barrels2013, barrels2012, barrels2011, barrels2010, barrels2009, barrels2008) FROM stdin;
Aberrant Ales	MI	58.0	60.2	74.2	59.2	101.6	120.8	145.9	150.0	152.1	180.3
Abide Brewing	GA	68.0	70.2	64.2	99.2	201.6	220.8	85.9	250.0	252.1	280.3
Adit Brewing	LA	98.0	90.2	124.2	159.2	221.6	310.8	185.9	190.0	252.1	380.3
Able Baker Brewing	NV	178.0	160.2	54.2	99.2	91.6	220.8	245.9	50.0	52.1	80.3
Able Ebenezer	NH	20.0	30.2	40.2	159.2	141.6	170.8	185.9	130.0	192.1	220.3
Accomplice Beer	WY	147.0	160.2	174.2	259.2	201.6	220.8	345.9	450.0	452.1	580.3
Acidulous Brewing	CO	98.0	90.2	84.2	89.2	161.6	180.8	135.9	250.0	352.1	300.3
Acopon Brewing	TX	56.0	64.2	73.2	89.2	101.6	125.8	95.9	110.0	115.1	183.3
Aftershock Brewing	CA	70.0	40.0	23.0	15.0	35.0	12.0	220.0	250.0	255.0	260.0
Afterthought Brewing	IL	58.5	61.2	79.2	29.2	121.6	129.8	245.9	250.0	452.1	588.3
Against the Grain	KY	51.0	77.2	78.2	129.2	121.6	150.8	165.9	130.0	111.1	173.3
Bard Tale Beer	MN	59.0	64.2	75.2	359.2	131.6	170.8	165.9	120.0	132.1	120.3
Bare Arms Brewing	TX	458.0	460.2	474.2	159.2	181.6	180.8	135.9	120.0	252.1	230.3
Bare Bones Brewery	WI	39.0	69.2	79.2	26.2	111.6	113.8	165.9	190.0	133.1	254.3
Bare Hands Brewery	IN	52.0	62.2	78.2	79.2	134.6	143.8	145.6	160.0	187.1	247.8
Barebottle Brewing	CA	115.6	120.2	94.2	109.2	103.6	180.8	145.9	210.0	252.1	278.3
Barhop Brewing	WA	56.4	64.2	75.2	56.2	81.6	127.8	175.9	120.0	152.1	300.3
BarkEater Craft	NY	101.0	160.2	140.2	180.2	91.6	126.8	145.9	151.0	158.1	183.3
Barker Brewing	NY	98.0	110.2	94.2	108.2	109.6	160.8	175.9	140.0	202.1	210.3
Barley Grill	MD	53.0	63.2	174.2	259.2	121.6	120.8	146.9	154.0	154.1	182.3
Barley Brothers	AZ	57.0	67.2	78.2	57.2	171.6	170.8	175.9	170.0	172.1	170.3
Garage Brewing	CA	59.0	50.2	74.2	89.2	201.6	130.8	165.9	170.0	192.1	204.3
Garden State Beer	NJ	99.0	90.2	94.2	99.2	101.6	170.8	265.9	240.0	199.1	180.4
Abigaile	CA	158.0	160.2	174.2	99.2	301.6	320.8	345.9	350.0	352.1	280.3
Abjuration Brewing	PA	38.0	160.2	174.2	89.2	201.6	90.8	145.9	450.0	452.1	480.3
Barking Duck	NC	128.0	30.2	84.2	159.2	121.6	130.8	175.9	140.0	142.1	200.3
\.


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

