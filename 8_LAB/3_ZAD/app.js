const express = require('express');
const redis = require('redis');
const { promisify } = require('util');
const bodyParser = require('body-parser');
const { Pool } = require('pg');
const path = require('path');

const app = express();
const port = 3000;

// Redis client setup
const redisClient = redis.createClient({
  host: 'redis',
  port: 6379
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

// Promisify Redis commands
const lpushAsync = promisify(redisClient.lpush).bind(redisClient);
const lrangeAsync = promisify(redisClient.lrange).bind(redisClient);

// PostgreSQL setup
const pgPool = new Pool({
  user: 'postgres',
  host: 'postgres',
  database: 'postgres',
  password: 'postgres_password',
  port: 5432,
});

pgPool.on('error', (err) => {
  console.error('PostgreSQL error:', err);
});

// Initialize PostgreSQL table
const initDb = async () => {
  try {
    await pgPool.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(100) UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('Database initialized successfully');
  } catch (error) {
    console.error('Error initializing database:', error);
  }
};

// Run DB initialization
initDb();

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Main page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="pl">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Express Redis PostgreSQL App</title>
      <style>
        body {
          font-family: Arial, sans-serif;
          max-width: 800px;
          margin: 0 auto;
          padding: 20px;
        }
        h1 {
          color: #333;
        }
        .container {
          display: flex;
          gap: 20px;
          margin-top: 20px;
        }
        .section {
          flex: 1;
          border: 1px solid #ddd;
          padding: 20px;
          border-radius: 5px;
        }
        form {
          margin-bottom: 20px;
        }
        input, button {
          padding: 8px;
          margin: 5px 0;
        }
        button {
          background-color: #4CAF50;
          color: white;
          border: none;
          cursor: pointer;
        }
        ul {
          list-style-type: none;
          padding: 0;
        }
        li {
          padding: 8px 0;
          border-bottom: 1px solid #eee;
        }
      </style>
    </head>
    <body>
      <h1>Express Redis PostgreSQL App</h1>
      
      <div class="container">
        <div class="section">
          <h2>Wiadomości (Redis)</h2>
          <form action="/messages" method="post">
            <input type="text" name="message" placeholder="Wpisz wiadomość" required><br>
            <button type="submit">Dodaj wiadomość</button>
          </form>
          <a href="/messages">Zobacz wszystkie wiadomości</a>
        </div>
        
        <div class="section">
          <h2>Użytkownicy (PostgreSQL)</h2>
          <form action="/users" method="post">
            <input type="text" name="username" placeholder="Nazwa użytkownika" required><br>
            <input type="email" name="email" placeholder="Email" required><br>
            <button type="submit">Dodaj użytkownika</button>
          </form>
          <a href="/users">Zobacz wszystkich użytkowników</a>
        </div>
      </div>
    </body>
    </html>
  `);
});

// Messages endpoints (Redis)
app.post('/messages', async (req, res) => {
  try {
    const message = req.body.message;
    if (!message) {
      return res.status(400).json({ error: 'Wiadomość nie może być pusta' });
    }

    await lpushAsync('messages', message);
    res.redirect('/messages');
  } catch (error) {
    console.error('Error saving message:', error);
    res.status(500).json({ error: 'Błąd podczas zapisywania wiadomości' });
  }
});

app.get('/messages', async (req, res) => {
  try {
    const messages = await lrangeAsync('messages', 0, -1);

    res.send(`
      <!DOCTYPE html>
      <html lang="pl">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Wszystkie wiadomości</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          h1 {
            color: #333;
          }
          ul {
            list-style-type: none;
            padding: 0;
          }
          li {
            padding: 10px;
            border-bottom: 1px solid #eee;
          }
          .empty {
            color: #777;
            font-style: italic;
          }
          .back {
            display: inline-block;
            margin-top: 20px;
            color: #4CAF50;
            text-decoration: none;
          }
          .back:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <h1>Wszystkie wiadomości</h1>
        <ul>
          ${messages.length ? messages.map(msg => `<li>${msg}</li>`).join('') : '<li class="empty">Brak wiadomości</li>'}
        </ul>
        <a href="/" class="back">Powrót do strony głównej</a>
      </body>
      </html>
    `);
  } catch (error) {
    console.error('Error retrieving messages:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania wiadomości' });
  }
});

// Users endpoints (PostgreSQL)
app.post('/users', async (req, res) => {
  try {
    const { username, email } = req.body;
    if (!username || !email) {
      return res.status(400).json({ error: 'Nazwa użytkownika i email są wymagane' });
    }

    const result = await pgPool.query(
      'INSERT INTO users (username, email) VALUES ($1, $2) RETURNING id',
      [username, email]
    );

    res.redirect('/users');
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Błąd podczas tworzenia użytkownika' });
  }
});

app.get('/users', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT * FROM users ORDER BY created_at DESC');
    const users = result.rows;

    res.send(`
      <!DOCTYPE html>
      <html lang="pl">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Wszyscy użytkownicy</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
          }
          h1 {
            color: #333;
          }
          table {
            width: 100%;
            border-collapse: collapse;
          }
          th, td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
            text-align: left;
          }
          th {
            background-color: #f2f2f2;
          }
          .empty {
            color: #777;
            font-style: italic;
            padding: 20px 0;
          }
          .back {
            display: inline-block;
            margin-top: 20px;
            color: #4CAF50;
            text-decoration: none;
          }
          .back:hover {
            text-decoration: underline;
          }
        </style>
      </head>
      <body>
        <h1>Wszyscy użytkownicy</h1>
        ${users.length ? `
          <table>
            <tr>
              <th>ID</th>
              <th>Nazwa użytkownika</th>
              <th>Email</th>
              <th>Data utworzenia</th>
            </tr>
            ${users.map(user => `
              <tr>
                <td>${user.id}</td>
                <td>${user.username}</td>
                <td>${user.email}</td>
                <td>${new Date(user.created_at).toLocaleString()}</td>
              </tr>
            `).join('')}
          </table>
        ` : '<p class="empty">Brak użytkowników</p>'}
        <a href="/" class="back">Powrót do strony głównej</a>
      </body>
      </html>
    `);
  } catch (error) {
    console.error('Error retrieving users:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania użytkowników' });
  }
});

// API endpoints
app.get('/api/messages', async (req, res) => {
  try {
    const messages = await lrangeAsync('messages', 0, -1);
    res.json({ messages });
  } catch (error) {
    console.error('Error retrieving messages:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania wiadomości' });
  }
});

app.get('/api/users', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT * FROM users ORDER BY created_at DESC');
    res.json({ users: result.rows });
  } catch (error) {
    console.error('Error retrieving users:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania użytkowników' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(port, () => {
  console.log(`Aplikacja działa pod adresem http://localhost:${port}`);
});
