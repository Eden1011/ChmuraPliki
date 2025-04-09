const express = require('express');
const mysql = require('mysql2/promise');

const app = express();
const port = 3000;

// Konfiguracja połączenia z MySQL
const dbConfig = {
  host: 'db',
  user: 'root',
  password: 'password',
  database: 'testdb'
};

app.get('/', async (req, res) => {
  try {
    // Nawiązanie połączenia z bazą danych
    const connection = await mysql.createConnection(dbConfig);

    // Wykonanie zapytania
    const [rows] = await connection.execute('SELECT * FROM users');

    // Zamknięcie połączenia
    await connection.end();

    // Przygotowanie odpowiedzi HTML
    let html = '<h1>Dane pobrane z bazy MySQL</h1>';
    html += '<table border="1"><tr><th>ID</th><th>Nazwa</th><th>Email</th></tr>';

    rows.forEach(row => {
      html += `<tr><td>${row.id}</td><td>${row.name}</td><td>${row.email}</td></tr>`;
    });

    html += '</table>';

    res.send(html);
  } catch (error) {
    console.error('Błąd podczas pobierania danych:', error);
    res.status(500).send(`<h1>Błąd połączenia z bazą danych</h1><p>${error.message}</p>`);
  }
});

app.listen(port, () => {
  console.log(`Aplikacja uruchomiona na porcie ${port}`);
});
