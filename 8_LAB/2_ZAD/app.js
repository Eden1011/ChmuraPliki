const express = require('express');
const redis = require('redis');
const { promisify } = require('util');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

const redisClient = redis.createClient({
  host: 'redis',
  port: 6379
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

const lpushAsync = promisify(redisClient.lpush).bind(redisClient);
const lrangeAsync = promisify(redisClient.lrange).bind(redisClient);

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app.get('/', (req, res) => {
  res.send(`
    <h1>Aplikacja do przechowywania wiadomości</h1>
    <form action="/messages" method="post">
      <input type="text" name="message" placeholder="Wpisz wiadomość" required>
      <button type="submit">Dodaj</button>
    </form>
    <p>Aby zobaczyć wszystkie wiadomości, odwiedź <a href="/messages">/messages</a></p>
  `);
});

// Dodaj nową wiadomość
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

// Pobierz wszystkie wiadomości
app.get('/messages', async (req, res) => {
  try {
    const messages = await lrangeAsync('messages', 0, -1);

    res.send(`
      <h1>Wszystkie wiadomości</h1>
      <ul>
        ${messages.map(msg => `<li>${msg}</li>`).join('')}
      </ul>
      <a href="/">Powrót do strony głównej</a>
    `);
  } catch (error) {
    console.error('Error retrieving messages:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania wiadomości' });
  }
});

// API endpoint do pobierania wiadomości w formacie JSON
app.get('/api/messages', async (req, res) => {
  try {
    const messages = await lrangeAsync('messages', 0, -1);
    res.json({ messages });
  } catch (error) {
    console.error('Error retrieving messages:', error);
    res.status(500).json({ error: 'Błąd podczas pobierania wiadomości' });
  }
});

app.listen(port, () => {
  console.log(`Aplikacja działa pod adresem http://localhost:${port}`);
});
