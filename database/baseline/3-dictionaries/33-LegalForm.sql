CREATE TABLE "LegalForm"
  ( id    SERIAL PRIMARY KEY
  , label text UNIQUE NOT NULL
  , synonyms text[]
  );

GRANT ALL ON "LegalForm" TO carma_db_sync;
GRANT ALL ON "LegalForm_id_seq" TO carma_db_sync;

COPY "LegalForm" (id, label) FROM stdin;
1	Физическое лицо
2	Юридическое лицо
\.

SELECT setval(pg_get_serial_sequence('"LegalForm"', 'id'), max(id)) from "LegalForm";
