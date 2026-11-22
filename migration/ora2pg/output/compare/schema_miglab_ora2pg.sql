--
-- PostgreSQL database dump
--

\restrict M9aZGrlKm6MiOfyzwfVbO6DIK7oVxv9oDm9Z5wt2HReUF4NMwvfrC4Q1POD8fTg

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
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE

 l_balance decimal(14,2);

BEGIN
 SELECT coalesce(total_billed,0)-coalesce(total_allowed,0)
 INTO STRICT l_balance FROM claim WHERE claim_id=p_claim_id;
 RETURN l_balance;
EXCEPTION WHEN no_data_found THEN RETURN NULL;
END;
$$;


--
-- Name: pr_recalculate_claim(bigint); Type: PROCEDURE; Schema: miglab; Owner: -
--

CREATE PROCEDURE miglab.pr_recalculate_claim(IN p_claim_id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE

    ora2pg_rowcount int;
l_billed  numeric;
    l_allowed numeric;
    l_message varchar(4000);

BEGIN

    SELECT coalesce(SUM(billed_amount),0),
           coalesce(SUM(allowed_amount),0)
    INTO STRICT l_billed,
         l_allowed
    FROM claim_detail
    WHERE claim_id = p_claim_id;

    UPDATE claim
       SET total_billed  = l_billed,
           total_allowed = l_allowed,
           claim_status  =
               CASE
                   WHEN claim_status = 'NEW'
                   THEN 'PROCESSING'
                   ELSE claim_status
               END
     WHERE claim_id = p_claim_id;

    GET DIAGNOSTICS ora2pg_rowcount = ROW_COUNT;
IF ora2pg_rowcount = 0 THEN
        RAISE EXCEPTION '%', 'Claim ID ' || p_claim_id || ' does not exist'
         USING ERRCODE = '45001';
    END IF;

    l_message := 'Claim recalculated successfully';

    INSERT INTO migration_audit(
        audit_id,
        process_name,
        source_count,
        target_count,
        status,
        message,
        created_timestamp
    )
    VALUES (
        nextval('seq_migration_audit'),
        'PR_RECALCULATE_CLAIM',
        1,
        1,
        'SUCCESS',
        l_message,
        statement_timestamp()
    );

EXCEPTION
    WHEN OTHERS THEN

        l_message := SUBSTR(SQLERRM,1,4000);

        INSERT INTO migration_audit(
            audit_id,
            process_name,
            source_count,
            target_count,
            status,
            message,
            created_timestamp
        )
        VALUES (
            nextval('seq_migration_audit'),
            'PR_RECALCULATE_CLAIM',
            1,
            0,
            'FAILED',
            l_message,
            statement_timestamp()
        );

        RAISE;
END;
$$;


--
-- Name: trigger_fct_trg_claim_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_claim_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.claim_id := nextval('seq_claim');RETURN NEW;
END
$$;


--
-- Name: trigger_fct_trg_claim_detail_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_claim_detail_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.claim_detail_id := nextval('seq_claim_detail');RETURN NEW;
END
$$;


--
-- Name: trigger_fct_trg_fee_schedule_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_fee_schedule_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.schedule_id := nextval('seq_fee_schedule');RETURN NEW;
END
$$;


--
-- Name: trigger_fct_trg_fee_schedule_detail_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_fee_schedule_detail_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.schedule_detail_id := nextval('seq_fee_schedule_detail');RETURN NEW;
END
$$;


--
-- Name: trigger_fct_trg_member_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_member_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.member_id := nextval('seq_member');RETURN NEW;
END
$$;


--
-- Name: trigger_fct_trg_migration_audit_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_migration_audit_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.audit_id := nextval('seq_migration_audit');RETURN NEW;
END
$$;


--
-- Name: trigger_fct_trg_provider_bi(); Type: FUNCTION; Schema: miglab; Owner: -
--

CREATE FUNCTION miglab.trigger_fct_trg_provider_bi() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN NEW.provider_id := nextval('seq_provider');RETURN NEW;
END
$$;


--
-- Name: get_status_label(character varying); Type: FUNCTION; Schema: pkg_claim_admin; Owner: -
--

CREATE FUNCTION pkg_claim_admin.get_status_label(p_status character varying) RETURNS character varying
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
        CASE p_status
            WHEN 'NEW' THEN
                RETURN 'Pending Intake';

            WHEN 'PROCESSING' THEN
                RETURN 'Under Review';

            WHEN 'PAID' THEN
                RETURN 'Completed';

            WHEN 'DENIED' THEN
                RETURN 'Rejected';

            ELSE
                RETURN 'Unknown';
        END CASE;
    END;
$$;


--
-- Name: recalculate_open_claims(); Type: PROCEDURE; Schema: pkg_claim_admin; Owner: -
--

CREATE PROCEDURE pkg_claim_admin.recalculate_open_claims()
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE

        c_claims CURSOR FOR
            SELECT claim_id
            FROM claim
            WHERE claim_status IN ('NEW','PROCESSING');

        l_count numeric := 0;


BEGIN

        FOR r IN c_claims LOOP

            CALL pr_recalculate_claim(r.claim_id);

            l_count := l_count + 1;

        END LOOP;

        CALL pkg_claim_admin.upsert_audit(
            'RECALCULATE_OPEN_CLAIMS',
            l_count,
            l_count,
            'SUCCESS',
            'Open claims processed successfully'
        );

    EXCEPTION
        WHEN OTHERS THEN

            CALL pkg_claim_admin.upsert_audit(
                'RECALCULATE_OPEN_CLAIMS',
                l_count,
                0,
                'FAILED',
                SUBSTR(SQLERRM,1,4000)
            );

            RAISE;

    END;
$$;


--
-- Name: upsert_audit(character varying, bigint, bigint, character varying, character varying); Type: PROCEDURE; Schema: pkg_claim_admin; Owner: -
--

CREATE PROCEDURE pkg_claim_admin.upsert_audit(IN p_process_name character varying, IN p_source_count bigint, IN p_target_count bigint, IN p_status character varying, IN p_message character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN

        MERGE INTO migration_audit a
        USING(
            SELECT p_process_name process_name

        ) s
        ON (
            a.process_name = s.process_name
            AND date_trunc('day', a.created_timestamp) = date_trunc('day', clock_timestamp())
        )

        WHEN MATCHED THEN
            UPDATE SET
                a.source_count      = p_source_count,
                a.target_count      = p_target_count,
                a.status            = p_status,
                a.message           = p_message,
                a.created_timestamp = statement_timestamp()

        WHEN NOT MATCHED THEN
            INSERT(
                audit_id,
                process_name,
                source_count,
                target_count,
                status,
                message,
                created_timestamp
            )
            VALUES (
                nextval('seq_migration_audit'),
                p_process_name,
                p_source_count,
                p_target_count,
                p_status,
                p_message,
                statement_timestamp()
            );

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
    service_date timestamp(0) without time zone NOT NULL,
    received_date timestamp(0) without time zone DEFAULT statement_timestamp(),
    claim_status character varying(20),
    total_billed numeric(14,2),
    total_allowed numeric(14,2),
    created_timestamp timestamp(6) without time zone DEFAULT statement_timestamp(),
    CONSTRAINT ck_claim_status CHECK (((claim_status)::text = ANY ((ARRAY['NEW'::character varying, 'PROCESSING'::character varying, 'PAID'::character varying, 'DENIED'::character varying])::text[])))
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
-- Name: fee_schedule; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.fee_schedule (
    schedule_id bigint NOT NULL,
    schedule_code character varying(30) NOT NULL,
    schedule_name character varying(150),
    effective_date timestamp(0) without time zone NOT NULL,
    termination_date timestamp(0) without time zone,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    description text,
    created_date timestamp(0) without time zone DEFAULT statement_timestamp(),
    updated_timestamp timestamp(6) without time zone DEFAULT statement_timestamp(),
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
    effective_date timestamp(0) without time zone NOT NULL,
    termination_date timestamp(0) without time zone
);


--
-- Name: member; Type: TABLE; Schema: miglab; Owner: -
--

CREATE TABLE miglab.member (
    member_id bigint NOT NULL,
    member_number character varying(30) NOT NULL,
    first_name character varying(100),
    last_name character varying(100),
    date_of_birth timestamp(0) without time zone,
    state_code character varying(2),
    active_flag character(1) DEFAULT 'Y'::bpchar,
    created_date timestamp(0) without time zone DEFAULT statement_timestamp(),
    CONSTRAINT ck_member_active CHECK ((active_flag = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
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
    created_timestamp timestamp(6) without time zone DEFAULT statement_timestamp()
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
    created_date timestamp(0) without time zone DEFAULT statement_timestamp(),
    updated_timestamp timestamp(6) without time zone DEFAULT statement_timestamp(),
    CONSTRAINT ck_provider_active CHECK ((active_flag = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


--
-- Name: seq_claim; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_claim
    START WITH 111201
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 100;


--
-- Name: seq_claim_detail; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_claim_detail
    START WITH 263896
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 100;


--
-- Name: seq_fee_schedule; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_fee_schedule
    START WITH 2221
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;


--
-- Name: seq_fee_schedule_detail; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_fee_schedule_detail
    START WITH 222221
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;


--
-- Name: seq_member; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_member
    START WITH 22241
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;


--
-- Name: seq_migration_audit; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_migration_audit
    START WITH 21
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;


--
-- Name: seq_provider; Type: SEQUENCE; Schema: miglab; Owner: -
--

CREATE SEQUENCE miglab.seq_provider
    START WITH 2241
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 20;


--
-- Name: v_active_fee_schedule; Type: VIEW; Schema: miglab; Owner: -
--

CREATE VIEW miglab.v_active_fee_schedule AS
 SELECT fs.schedule_id,
    fs.schedule_code,
    fs.schedule_name,
    fs.effective_date,
    fs.termination_date,
    COALESCE(fs.termination_date, '2999-12-31 00:00:00'::timestamp(0) without time zone) AS effective_end_date,
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
        CASE
            WHEN ((c.claim_status)::text = 'NEW'::text) THEN 'Pending Intake'::text
            WHEN ((c.claim_status)::text = 'PROCESSING'::text) THEN 'Under Review'::text
            WHEN ((c.claim_status)::text = 'PAID'::text) THEN 'Completed'::text
            WHEN ((c.claim_status)::text = 'DENIED'::text) THEN 'Rejected'::text
            ELSE 'Unknown'::text
        END AS status_description,
    COALESCE(c.total_billed, (0)::numeric) AS total_billed,
    COALESCE(c.total_allowed, (0)::numeric) AS total_allowed,
    (COALESCE(c.total_billed, (0)::numeric) - COALESCE(c.total_allowed, (0)::numeric)) AS adjustment_amount
   FROM ((miglab.claim c
     JOIN miglab.member m ON ((m.member_id = c.member_id)))
     JOIN miglab.provider p ON ((p.provider_id = c.provider_id)));


--
-- Name: claim claim_claim_number_key; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim
    ADD CONSTRAINT claim_claim_number_key UNIQUE (claim_number);


--
-- Name: claim_detail claim_detail_claim_id_line_number_key; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim_detail
    ADD CONSTRAINT claim_detail_claim_id_line_number_key UNIQUE (claim_id, line_number);


--
-- Name: claim_detail claim_detail_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim_detail
    ADD CONSTRAINT claim_detail_pkey PRIMARY KEY (claim_detail_id);


--
-- Name: claim claim_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.claim
    ADD CONSTRAINT claim_pkey PRIMARY KEY (claim_id);


--
-- Name: fee_schedule_detail fee_schedule_detail_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule_detail
    ADD CONSTRAINT fee_schedule_detail_pkey PRIMARY KEY (schedule_detail_id);


--
-- Name: fee_schedule fee_schedule_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule
    ADD CONSTRAINT fee_schedule_pkey PRIMARY KEY (schedule_id);


--
-- Name: fee_schedule fee_schedule_schedule_code_key; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.fee_schedule
    ADD CONSTRAINT fee_schedule_schedule_code_key UNIQUE (schedule_code);


--
-- Name: member member_member_number_key; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.member
    ADD CONSTRAINT member_member_number_key UNIQUE (member_number);


--
-- Name: member member_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (member_id);


--
-- Name: migration_audit migration_audit_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.migration_audit
    ADD CONSTRAINT migration_audit_pkey PRIMARY KEY (audit_id);


--
-- Name: provider provider_pkey; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.provider
    ADD CONSTRAINT provider_pkey PRIMARY KEY (provider_id);


--
-- Name: provider provider_provider_code_key; Type: CONSTRAINT; Schema: miglab; Owner: -
--

ALTER TABLE ONLY miglab.provider
    ADD CONSTRAINT provider_provider_code_key UNIQUE (provider_code);


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
-- Name: claim trg_claim_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_claim_bi BEFORE INSERT ON miglab.claim FOR EACH ROW WHEN ((new.claim_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_claim_bi();


--
-- Name: claim_detail trg_claim_detail_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_claim_detail_bi BEFORE INSERT ON miglab.claim_detail FOR EACH ROW WHEN ((new.claim_detail_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_claim_detail_bi();


--
-- Name: fee_schedule trg_fee_schedule_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_fee_schedule_bi BEFORE INSERT ON miglab.fee_schedule FOR EACH ROW WHEN ((new.schedule_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_fee_schedule_bi();


--
-- Name: fee_schedule_detail trg_fee_schedule_detail_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_fee_schedule_detail_bi BEFORE INSERT ON miglab.fee_schedule_detail FOR EACH ROW WHEN ((new.schedule_detail_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_fee_schedule_detail_bi();


--
-- Name: member trg_member_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_member_bi BEFORE INSERT ON miglab.member FOR EACH ROW WHEN ((new.member_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_member_bi();


--
-- Name: migration_audit trg_migration_audit_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_migration_audit_bi BEFORE INSERT ON miglab.migration_audit FOR EACH ROW WHEN ((new.audit_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_migration_audit_bi();


--
-- Name: provider trg_provider_bi; Type: TRIGGER; Schema: miglab; Owner: -
--

CREATE TRIGGER trg_provider_bi BEFORE INSERT ON miglab.provider FOR EACH ROW WHEN ((new.provider_id IS NULL)) EXECUTE FUNCTION miglab.trigger_fct_trg_provider_bi();


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

\unrestrict M9aZGrlKm6MiOfyzwfVbO6DIK7oVxv9oDm9Z5wt2HReUF4NMwvfrC4Q1POD8fTg

