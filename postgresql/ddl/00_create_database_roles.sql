-- Application owner (equivalent of Oracle user MIGLAB)
CREATE ROLE miglab
    LOGIN
    PASSWORD '<MIGLAB_PG_PASSWORD>';
 
-- Read-only role for validation and reporting
CREATE ROLE miglab_ro
    LOGIN
    PASSWORD '<MIGLAB_RO_PASSWORD>';
 
-- Target database owned by the application role
CREATE DATABASE miglabdb
    OWNER miglab
    ENCODING 'UTF8'
    TEMPLATE template0;
 
-- Only explicitly allowed roles may connect
REVOKE ALL ON DATABASE miglabdb FROM PUBLIC;
GRANT CONNECT ON DATABASE miglabdb TO miglab, miglab_ro;
