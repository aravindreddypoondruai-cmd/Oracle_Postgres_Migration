--
-- PostgreSQL database dump
--

\restrict beMgB61DknMv5tsjRIoovkL8avDJVDMbsbhxb2ImChIcHPLfUVJLeW5c2arQRHh

-- Dumped from database version 18.7 (Debian 18.7-1.pgdg13+5)
-- Dumped by pg_dump version 18.7 (Debian 18.7-1.pgdg13+5)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: miglab; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA miglab;


--
-- Name: pkg_claim_admin; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pkg_claim_admin;


--
-- Name: fn_claim_balance(bigint); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.fn_claim_balance(p_claim_id bigint) RETURNS numeric
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    l_balance numeric(14,2);
BEGIN
    SELECT COALESCE(total_billed, 0) - COALESCE(total_allowed, 0)
      INTO l_balance
      FROM miglab.claim
     WHERE claim_id = p_claim_id;
 
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
 
    RETURN l_balance;
END;
$$;


--
-- Name: pr_recalculate_claim(bigint); Type: PROCEDURE; Schema: miglab; Owner: -
--

CREATE PROCEDURE miglab.pr_recalculate_claim(IN p_claim_id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    l_billed  numeric(14,2);
    l_allowed numeric(14,2);
BEGIN
    SELECT COALESCE(SUM(billed_amount), 0),
           COALESCE(SUM(allowed_amount), 0)
      INTO l_billed, l_allowed
      FROM miglab.claim_detail
     WHERE claim_id = p_claim_id;
 
    UPDATE miglab.claim
       SET total_billed  = l_billed,
           total_allowed = l_allowed,
           claim_status  = CASE claim_status WHEN 'NEW' THEN 'PROCESSING'
                                             ELSE claim_status END
     WHERE claim_id = p_claim_id;
 
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Claim ID % does not exist', p_claim_id
              USING ERRCODE = 'P0001';
    END IF;
 
    INSERT INTO miglab.migration_audit
           (process_name, source_count, target_count, status, message)
    VALUES ('PR_RECALCULATE_CLAIM', 1, 1, 'SUCCESS',
            'Claim ' || p_claim_id || ' recalculated at ' ||
            to_char(clock_timestamp(), 'YYYY-MM-DD HH24:MI:SS.US'));
 
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO miglab.migration_audit
               (process_name, source_count, target_count, status, message)
        VALUES ('PR_RECALCULATE_CLAIM', 1, 0, 'FAILED', left(SQLERRM, 4000));
        RAISE;
END;
$$;


--
-- Name: get_status_label(character varying); Type: FUNCTION; Schema: pkg_claim_admin; Owner: -
--

CREATE FUNCTION pkg_claim_admin.get_status_label(p_status character varying) RETURNS character varying
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT CASE p_status
                WHEN 'NEW'        THEN 'Pending Intake'
                WHEN 'PROCESSING' THEN 'Under Review'
                WHEN 'PAID'       THEN 'Completed'
                WHEN 'DENIED'     THEN 'Rejected'
                ELSE 'Unknown'
           END;
$$;


--
-- Name: recalculate_open_claims(); Type: PROCEDURE; Schema: pkg_claim_admin; Owner: -
--

CREATE PROCEDURE pkg_claim_admin.recalculate_open_claims()
    LANGUAGE plpgsql
    AS $$
DECLARE
    r       record;
    l_count bigint := 0;
BEGIN
    FOR r IN SELECT claim_id
               FROM miglab.claim
              WHERE claim_status IN ('NEW', 'PROCESSING')
    LOOP
        CALL miglab.pr_recalculate_claim(r.claim_id);
        l_count := l_count + 1;
    END LOOP;
 
    CALL pkg_claim_admin.upsert_audit('RECALCULATE_OPEN_CLAIMS', l_count, l_count,
                                      'SUCCESS', 'Open claims processed successfully');
EXCEPTION
    WHEN OTHERS THEN
        CALL pkg_claim_admin.upsert_audit('RECALCULATE_OPEN_CLAIMS', l_count, 0,
                                          'FAILED', left(SQLERRM, 4000));
        RAISE;
END;
$$;


--
-- Name: upsert_audit(character varying, bigint, bigint, character varying, character varying); Type: PROCEDURE; Schema: pkg_claim_admin; Owner: -
--

CREATE PROCEDURE pkg_claim_admin.upsert_audit(IN p_process_name character varying, IN p_source_count bigint, IN p_target_count bigint, IN p_status character varying, IN p_message character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    MERGE INTO miglab.migration_audit a
    USING (SELECT p_process_name AS process_name) s
       ON a.process_name = s.process_name
      AND a.created_timestamp::date = current_date
    WHEN MATCHED THEN
        UPDATE SET source_count      = p_source_count,
                   target_count      = p_target_count,
                   status            = p_status,
                   message           = p_message,
                   created_timestamp = localtimestamp
    WHEN NOT MATCHED THEN
        INSERT (process_name, source_count, target_count,
                status, message, created_timestamp)
        VALUES (p_process_name, p_source_count, p_target_count,
                p_status, p_message, localtimestamp);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: claim; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.claim (
    claim_id bigint NOT NULL,
    claim_number character varying(30) NOT NULL,
    member_id bigint NOT NULL,
    provider_id bigint NOT NULL,
    service_date date NOT NULL,
    received_date timestamp(0) without time zone DEFAULT LOCALTIMESTAMP(0),
    claim_status character varying(20),
    total_billed numeric(14,2),
    total_allowed numeric(14,2),
    created_timestamp timestamp(6) without time zone DEFAULT LOCALTIMESTAMP,
    CONSTRAINT ck_claim_status CHECK (((claim_status)::text = ANY ((ARRAY['NEW'::character varying, 'PROCESSING'::character varying, 'PAID'::character varying, 'DENIED'::character varying])::text[])))
);


--
-- Name: claim_claim_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.claim ALTER COLUMN claim_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.claim_claim_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: claim_detail; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.claim_detail (
    claim_detail_id bigint NOT NULL,
    claim_id bigint NOT NULL,
    line_number integer NOT NULL,
    procedure_code character varying(20),
    modifier_code character varying(10),
    billed_amount numeric(12,2),
    allowed_amount numeric(12,2)
);


--
-- Name: claim_detail_claim_detail_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.claim_detail ALTER COLUMN claim_detail_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.claim_detail_claim_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fee_schedule; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.fee_schedule (
    schedule_id bigint NOT NULL,
    schedule_code character varying(30) NOT NULL,
    schedule_name character varying(150),
    effective_date date NOT NULL,
    termination_date date,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    description text,
    created_date timestamp(0) without time zone DEFAULT LOCALTIMESTAMP(0),
    updated_timestamp timestamp(6) without time zone DEFAULT LOCALTIMESTAMP,
    CONSTRAINT ck_fee_schedule_status CHECK (((status)::text = ANY ((ARRAY['ACTIVE'::character varying, 'INACTIVE'::character varying])::text[])))
);


--
-- Name: fee_schedule_detail; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.fee_schedule_detail (
    schedule_detail_id bigint NOT NULL,
    schedule_id bigint NOT NULL,
    procedure_code character varying(20) NOT NULL,
    modifier_code character varying(10),
    allowed_amount numeric(12,2) NOT NULL,
    effective_date date NOT NULL,
    termination_date date
);


--
-- Name: fee_schedule_detail_schedule_detail_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.fee_schedule_detail ALTER COLUMN schedule_detail_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.fee_schedule_detail_schedule_detail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: fee_schedule_schedule_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.fee_schedule ALTER COLUMN schedule_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.fee_schedule_schedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: member; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.member (
    member_id bigint NOT NULL,
    member_number character varying(30) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    date_of_birth date,
    state_code character varying(2),
    active_flag character(1) DEFAULT 'Y'::bpchar,
    created_date timestamp(0) without time zone DEFAULT LOCALTIMESTAMP(0),
    CONSTRAINT ck_member_active CHECK ((active_flag = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


--
-- Name: member_member_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.member ALTER COLUMN member_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.member_member_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: migration_audit; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.migration_audit (
    audit_id bigint NOT NULL,
    process_name character varying(100),
    source_count bigint,
    target_count bigint,
    status character varying(20),
    message character varying(4000),
    created_timestamp timestamp(6) without time zone DEFAULT LOCALTIMESTAMP
);


--
-- Name: migration_audit_audit_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.migration_audit ALTER COLUMN audit_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.migration_audit_audit_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: provider; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.provider (
    provider_id bigint NOT NULL,
    provider_code character varying(20) NOT NULL,
    provider_name character varying(150) NOT NULL,
    specialty character varying(100),
    state_code character varying(2),
    active_flag character(1) DEFAULT 'Y'::bpchar,
    created_date timestamp(0) without time zone DEFAULT LOCALTIMESTAMP(0),
    updated_timestamp timestamp(6) without time zone DEFAULT LOCALTIMESTAMP,
    CONSTRAINT ck_provider_active CHECK ((active_flag = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


--
-- Name: provider_provider_id_seq; Type: SEQUENCE; Schema: miglab; Owner: -
--

ALTER TABLE miglab.provider ALTER COLUMN provider_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME miglab.provider_provider_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: v_active_fee_schedule; Type: VIEW; Schema: miglab; Owner: -
--

CREATE VIEW miglab.v_active_fee_schedule AS
 SELECT fs.schedule_id,
    fs.schedule_code,
    fs.schedule_name,
    fs.effective_date,
    fs.termination_date,
    COALESCE(fs.termination_date, '2999-12-31'::date) AS effective_end_date,
    fs.status,
    count(fsd.schedule_detail_id) AS detail_count,
    COALESCE(avg(fsd.allowed_amount), (0)::numeric) AS average_allowed_amount
   FROM (miglab.fee_schedule fs
     LEFT JOIN miglab.fee_schedule_detail fsd ON ((fsd.schedule_id = fs.schedule_id)))
  WHERE ((fs.status)::text = 'ACTIVE'::text)
  GROUP BY fs.schedule_id, fs.schedule_code, fs.schedule_name, fs.effective_date, fs.termination_date, fs.status;


--
-- Name: v_claim_summary; Type: VIEW; Schema: miglab; Owner: -
--

CREATE VIEW miglab.v_claim_summary AS
 SELECT c.claim_id,
    c.claim_number,
    m.member_number,
    p.provider_code,
    p.provider_name,
    c.service_date,
    c.claim_status,
        CASE c.claim_status
            WHEN 'NEW'::text THEN 'Pending Intake'::text
            WHEN 'PROCESSING'::text THEN 'Under Review'::text
            WHEN 'PAID'::text THEN 'Completed'::text
            WHEN 'DENIED'::text THEN 'Rejected'::text
            ELSE 'Unknown'::text
        END AS status_description,
    COALESCE(c.total_billed, (0)::numeric) AS total_billed,
    COALESCE(c.total_allowed, (0)::numeric) AS total_allowed,
    (COALESCE(c.total_billed, (0)::numeric) - COALESCE(c.total_allowed, (0)::numeric)) AS adjustment_amount
   FROM ((miglab.claim c
     JOIN miglab.member m ON ((m.member_id = c.member_id)))
     JOIN miglab.provider p ON ((p.provider_id = c.provider_id)));


--
-- Name: claim pk_claim; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim
    ADD CONSTRAINT pk_claim PRIMARY KEY (claim_id);


--
-- Name: claim_detail pk_claim_detail; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim_detail
    ADD CONSTRAINT pk_claim_detail PRIMARY KEY (claim_detail_id);


--
-- Name: fee_schedule pk_fee_schedule; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule
    ADD CONSTRAINT pk_fee_schedule PRIMARY KEY (schedule_id);


--
-- Name: fee_schedule_detail pk_fee_schedule_detail; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule_detail
    ADD CONSTRAINT pk_fee_schedule_detail PRIMARY KEY (schedule_detail_id);


--
-- Name: member pk_member; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.member
    ADD CONSTRAINT pk_member PRIMARY KEY (member_id);


--
-- Name: migration_audit pk_migration_audit; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.migration_audit
    ADD CONSTRAINT pk_migration_audit PRIMARY KEY (audit_id);


--
-- Name: provider pk_provider; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.provider
    ADD CONSTRAINT pk_provider PRIMARY KEY (provider_id);


--
-- Name: claim_detail uk_claim_line; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim_detail
    ADD CONSTRAINT uk_claim_line UNIQUE (claim_id, line_number);


--
-- Name: claim uk_claim_number; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim
    ADD CONSTRAINT uk_claim_number UNIQUE (claim_number);


--
-- Name: fee_schedule uk_fee_schedule_code; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule
    ADD CONSTRAINT uk_fee_schedule_code UNIQUE (schedule_code);


--
-- Name: member uk_member_number; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.member
    ADD CONSTRAINT uk_member_number UNIQUE (member_number);


--
-- Name: provider uk_provider_code; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.provider
    ADD CONSTRAINT uk_provider_code UNIQUE (provider_code);


--
-- Name: idx_claim_detail_claim; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_claim_detail_claim ON miglab.claim_detail USING btree (claim_id);


--
-- Name: idx_claim_member; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_claim_member ON miglab.claim USING btree (member_id);


--
-- Name: idx_claim_provider; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_claim_provider ON miglab.claim USING btree (provider_id);


--
-- Name: idx_claim_service_date; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_claim_service_date ON miglab.claim USING btree (service_date);


--
-- Name: idx_claim_status; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_claim_status ON miglab.claim USING btree (claim_status);


--
-- Name: idx_fsd_proc_code; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_fsd_proc_code ON miglab.fee_schedule_detail USING btree (procedure_code);


--
-- Name: idx_fsd_schedule; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_fsd_schedule ON miglab.fee_schedule_detail USING btree (schedule_id);


--
-- Name: idx_provider_specialty; Type: INDEX; Schema: miglab; Owner: -
--

CREATE INDEX idx_provider_specialty ON miglab.provider USING btree (specialty);


--
-- Name: claim_detail fk_claim_detail_claim; Type: FK CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim_detail
    ADD CONSTRAINT fk_claim_detail_claim FOREIGN KEY (claim_id) REFERENCES miglab.claim(claim_id);


--
-- Name: claim fk_claim_member; Type: FK CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim
    ADD CONSTRAINT fk_claim_member FOREIGN KEY (member_id) REFERENCES miglab.member(member_id);


--
-- Name: claim fk_claim_provider; Type: FK CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim
    ADD CONSTRAINT fk_claim_provider FOREIGN KEY (provider_id) REFERENCES miglab.provider(provider_id);


--
-- Name: fee_schedule_detail fk_fsd_schedule; Type: FK CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule_detail
    ADD CONSTRAINT fk_fsd_schedule FOREIGN KEY (schedule_id) REFERENCES miglab.fee_schedule(schedule_id);


--
-- PostgreSQL database dump complete
--

\unrestrict beMgB61DknMv5tsjRIoovkL8avDJVDMbsbhxb2ImChIcHPLfUVJLeW5c2arQRHh

