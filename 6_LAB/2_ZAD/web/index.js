const express = require('express');
const mysql = require('mysql2');
const app = express();
const port = 3000;

const dbConfig = {
  host: 'db',
  user: 'root',
  password: 'rootpass',
  database: 'testdb'
};

function connectWithRetry(retries = 10, delay = 2000) {
  const connection = mysql.createConnection(dbConfig);

  connection.connect(err => {
    if (err) {
      if (retries <= 0) {
        console.error('Nie udało się połączyć z bazą danych. Zbyt wiele prób.');
        process.exit(1);
      }
      console.log(`Połączenie nieudane. Ponowna próba za ${delay / 1000}s... (${retries} pozostało)`);
      setTimeout(() => connectWithRetry(retries - 1, delay), delay);
    } else {
      console.log('Połączono z bazą danych.');

      app.get('/', (req, res) => {
        connection.query('SELECT NOW() as now', (err, results) => {
          if (err) {
            res.status(500).send('Błąd zapytania: ' + err.message);
          } else {
            res.send(`Połączenie z bazą danych działa! Czas DB: ${results[0].now}`);
          }
        });
      });

      app.listen(port, () => {
        console.log(`Aplikacja działa na porcie ${port}`);
      });
    }
  });
}

connectWithRetry();
