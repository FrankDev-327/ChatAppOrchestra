DO $$
DECLARE
    batch_size INT := 10000;
    total INT := 1000000;
    i INT := 0;
BEGIN
    CREATE TEMP TABLE temp_users (
        username VARCHAR,
        password VARCHAR,
        email VARCHAR,
        first_name VARCHAR,
        last_name VARCHAR,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
    );

    WHILE i < total LOOP
        INSERT INTO temp_users
        SELECT
            'user_' || (i + s) AS username,
            md5(random()::text) AS password,
            'user_' || (i + s) || '@example.com' AS email,
            (ARRAY['James','John','Robert','Michael','William','David','Richard','Joseph','Thomas','Charles',
                   'Ana','Maria','Sandra','Patricia','Linda','Barbara','Elizabeth','Jennifer','Maria','Susan'])[floor(random()*20+1)] AS first_name,
            (ARRAY['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Wilson','Taylor',
                   'Moore','Anderson','Thomas','Jackson','White','Harris','Martin','Thompson','Young','King'])[floor(random()*20+1)] AS last_name,
            NOW() - (random() * interval '3 years') AS created_at,
            NOW() AS updated_at
        FROM generate_series(1, batch_size) s;

        i := i + batch_size;

        IF mod(i, 100000) = 0 THEN
            RAISE NOTICE 'Generated % rows...', i;
        END IF;
    END LOOP;

    INSERT INTO users (username, password, email, first_name, last_name, created_at, updated_at)
    SELECT * FROM temp_users;

    DROP TABLE temp_users;

    RAISE NOTICE 'Done! Inserted % users.', total;
END $$;