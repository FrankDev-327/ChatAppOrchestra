-- Table: public.users

-- DROP TABLE IF EXISTS public.users;

CREATE TABLE IF NOT EXISTS public.users
(
    id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
    first_name character varying(80) COLLATE pg_catalog."default" NOT NULL,
    last_name character varying(80) COLLATE pg_catalog."default" NOT NULL,
    email character varying(150) COLLATE pg_catalog."default" NOT NULL,
    country_id integer,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT users_pkey PRIMARY KEY (id),
    CONSTRAINT users_email_key UNIQUE (email),
    CONSTRAINT users_country_id_fkey FOREIGN KEY (country_id)
        REFERENCES public.countries (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE NO ACTION
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.users
    OWNER to webdevuser;


SELECT
  u.id,
  u.first_name,
  rw.body        AS review_body,
  rw.rating,
  ctr.name       AS country_name,
  ctr.code,
  prod.name      AS product_name,
  ct.name        AS category_name,
  ord.unit_price,
  ord.quantity
FROM users u
JOIN countries   ctr  ON ctr.id  = u.country_id
JOIN reviews     rw   ON rw.user_id  = u.id
JOIN products    prod ON prod.id = rw.product_id
JOIN categories  ct   ON ct.id   = prod.category_id
JOIN orders      o    ON o.user_id  = u.id
JOIN order_items ord  ON ord.order_id = o.id AND ord.product_id = prod.id
ORDER BY ctr.name;

SELECT
  u.id,
  u.first_name,
  rw.body        AS review_body,
  rw.rating,
  ctr.name       AS country_name,
  ctr.code,
  prod.name      AS product_name,
  ct.name        AS category_name,
  ord.unit_price,
  ord.quantity,
  word_similarity('Dell', prod.name) AS similarity  
FROM users u
JOIN countries   ctr  ON ctr.id  = u.country_id
JOIN reviews     rw   ON rw.user_id  = u.id
JOIN products    prod ON prod.id = rw.product_id
JOIN categories  ct   ON ct.id   = prod.category_id
JOIN orders      o    ON o.user_id  = u.id
JOIN order_items ord  ON ord.order_id = o.id AND ord.product_id = prod.id
WHERE prod.name % 'Dell'  
ORDER BY similarity DESC;      

-----------------------------------

SELECT
  u.id,
  u.first_name,
  prod.name      AS product_name,
  ct.name        AS category_name,
  GREATEST(
    word_similarity('Dell', prod.name),
    word_similarity('phone', ct.name)
  ) AS similarity                                     -- ← best score across both fields
FROM users u
JOIN countries   ctr  ON ctr.id      = u.country_id
JOIN reviews     rw   ON rw.user_id  = u.id
JOIN products    prod ON prod.id     = rw.product_id
JOIN categories  ct   ON ct.id       = prod.category_id
JOIN orders      o    ON o.user_id   = u.id
JOIN order_items ord  ON ord.order_id = o.id AND ord.product_id = prod.id
WHERE prod.name % 'Dell' OR ct.name % 'phone'
ORDER BY similarity DESC;

SET pg_trgm.word_similarity_threshold = 0.9;
SELECT
  u.id,
  u.first_name,
  ctr.name       AS country_name,
  ctr.code,
  SUM(ord.unit_price) AS total_price
FROM users u
JOIN countries ctr
  ON ctr.id = u.country_id
JOIN reviews rw
  ON rw.user_id = u.id
JOIN products prod
  ON prod.id = rw.product_id
JOIN categories ct
  ON ct.id = prod.category_id
JOIN orders o
  ON o.user_id = u.id
JOIN order_items ord
  ON ord.order_id = o.id
 AND ord.product_id = prod.id
WHERE prod.name % 'Produ'
GROUP BY
  u.id,
  u.first_name,
  ctr.name,
  ctr.code
HAVING SUM(ord.unit_price) >= 100
ORDER BY total_price;

select * from reviews

explain analyze SELECT
  u.first_name,
  SUM(rating) as rating_sum,
  word_similarity('Taylor', u.last_name) as similarity
FROM reviews r
join users u on u.id = r.user_id
where u.last_name % 'Taylor'
GROUP BY u.first_name, u.last_name, r.user_id
having sum(rating) > 15 
ORDER BY r.user_id ASC;

-- ← best match first
SHOW pg_trgm.similarity_threshold;
-------------------------------

 SELECT
  u.id,
  u.first_name,
  rw.body        AS review_body,
  rw.rating,
  ctr.name       AS country_name,
  ctr.code,
  prod.name      AS product_name,
  ct.name        AS category_name,
  ord.unit_price,
  ord.quantity,
  word_similarity('phone', prod.name) AS similarity   -- ← add this
FROM users u
JOIN countries   ctr  ON ctr.id      = u.country_id
JOIN reviews     rw   ON rw.user_id  = u.id
JOIN products    prod ON prod.id     = rw.product_id
JOIN categories  ct   ON ct.id       = prod.category_id
JOIN orders      o    ON o.user_id   = u.id
JOIN order_items ord  ON ord.order_id = o.id AND ord.product_id = prod.id
WHERE prod.name % 'phone'                             -- ← pre-filter with GIN index
ORDER BY similarity DESC;                             -- ← best match first


explain select u.first_name, u.last_name, 
word_similarity('fra', u.first_name) AS similarity_name,
word_similarity('Taylor', u.last_name) AS similarity_last_name
from users as u
where u.first_name % 'fra' OR u.last_name % 'Taylor'
and word_similarity('fra', u.first_name) >= 0.5
ORDER BY similarity_name, similarity_last_name ASC;   

ANALYZE products;

explain ANALYZE select rw.id, rw.body, rw.created_at, u.first_name from reviews as rw
join users u on u.id = rw.user_id
where rw.created_at < CURRENT_DATE and rw.created_at > '2026-05-10 00:00:00'
and u.first_name % 'ev';

