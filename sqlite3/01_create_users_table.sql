CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL,
    password TEXT NOT NULL
);

INSERT INTO users (email, password) VALUES
    ('test1@example.com', '1234'),
    ('test2@example.com', 'abcd');
