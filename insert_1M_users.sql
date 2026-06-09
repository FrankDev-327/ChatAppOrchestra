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

-- new data for messages

ALTER TABLE chat_messages ALTER COLUMN position TYPE text USING position::text;

DO $$
DECLARE
    batch_size INT := 10000;
    total INT := 1000000;
    i INT := 0;
    message_types TEXT[] := ARRAY['TEXT', 'IMAGE', 'COORDINATES', 'TEMPLATE', 'DOCUMENT'];
    sample_contents TEXT[] := ARRAY[
        'Hey, how are you?',
        'Please check the task assigned to you.',
        'Meeting at 3pm today.',
        'Can you send me the report?',
        'Task completed successfully.',
        'I will be late today.',
        'Please review the document.',
        'Call me when you are free.',
        'The car needs maintenance.',
        'Location updated.'
    ];
BEGIN
    CREATE TEMP TABLE temp_chat_messages (
        sender_id INT,
        receiver_id INT,
        group_id INT,
        task_id INT,
        "parentTaskId" INT,
        content TEXT,
        file_url TEXT,
        message_type chat_messages_message_type_enum,
        created_at TIMESTAMP,
        position TEXT
    );

    WHILE i < total LOOP
        INSERT INTO temp_chat_messages
        SELECT
            (random() * 999999 + 1)::int AS sender_id,
            CASE WHEN random() > 0.3 THEN (random() * 999999 + 1)::int ELSE NULL END AS receiver_id,
            CASE WHEN random() > 0.6 THEN (random() * 1000 + 1)::int ELSE NULL END AS group_id,
            CASE WHEN random() > 0.5 THEN (random() * 10000 + 1)::int ELSE NULL END AS task_id,
            CASE WHEN random() > 0.7 THEN (random() * 10000 + 1)::int ELSE NULL END AS "parentTaskId",
            sample_contents[(floor(random() * 10) + 1)::int] AS content,
            CASE WHEN random() > 0.8 THEN 'https://files.example.com/file_' || (random() * 100000)::int || '.jpg' ELSE NULL END AS file_url,
            (message_types[(floor(random() * 5) + 1)::int])::chat_messages_message_type_enum AS message_type,
            NOW() - (random() * interval '2 years') AS created_at,
            CASE WHEN random() > 0.7 THEN '{"lat": ' || (random() * 90)::numeric(9,6)::text || ', "lng": ' || (random() * 180)::numeric(9,6)::text || '}' ELSE NULL END AS position
        FROM generate_series(1, batch_size) s;

        i := i + batch_size;

        IF mod(i, 100000) = 0 THEN
            RAISE NOTICE 'Generated % rows...', i;
        END IF;
    END LOOP;

    INSERT INTO chat_messages (sender_id, receiver_id, group_id, task_id, "parentTaskId", content, file_url, message_type, created_at, position)
    SELECT sender_id, receiver_id, group_id, task_id, "parentTaskId", content, file_url, message_type, created_at, position
    FROM temp_chat_messages;

    DROP TABLE temp_chat_messages;

    RAISE NOTICE 'Done! Inserted % chat messages.', total;
END $$;

SELECT u.id as user_id, 
cm.id as chat_id, 
cm.receiver_id as chat_receiver_id, 
cm.sender_id as chat_sender_id,
cm.content as chat_content, 
u.username as user_name, 
u.email as user_email,
cm.created_at as chat_created_at
FROM public.chat_messages cm
JOIN users u ON u.id = cm.sender_id
WHERE u.id >= 1000 AND u.id <= 2000
ORDER BY u.id ASC


ALTER TABLE chat_messages ADD COLUMN search_vector tsvector;

UPDATE chat_messages SET search_vector = to_tsvector('english', coalesce(content, ''));

CREATE INDEX idx_chat_messages_search_vector 
ON chat_messages USING GIN(search_vector);

SELECT cm.id, cm.sender_id, cm.receiver_id, cm.content
FROM chat_messages cm
WHERE search_vector @@ to_tsquery('english', 'task')
ORDER BY cm.id ASC;

SELECT cm.id, cm.sender_id, cm.content,
ts_rank(search_vector, to_tsquery('english', 'task')) AS rank
FROM chat_messages cm
WHERE search_vector @@ to_tsquery('english', 'task')
ORDER BY rank DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT * FROM chat_messages 
WHERE content ILIKE '%task%';

EXPLAIN ANALYZE
SELECT * FROM chat_messages 
WHERE search_vector @@ to_tsquery('english', 'task');