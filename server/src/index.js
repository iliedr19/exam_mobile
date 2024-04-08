var koa = require('koa');
var app = module.exports = new koa();
const server = require('http').createServer(app.callback());
const WebSocket = require('ws');
const wss = new WebSocket.Server({ server });
const Router = require('koa-router');
const cors = require('@koa/cors');
const bodyParser = require('koa-bodyparser');

app.use(bodyParser());

app.use(cors());

app.use(middleware);

function middleware(ctx, next) {
  const start = new Date();
  return next().then(() => {
    const ms = new Date() - start;
    console.log(`${start.toLocaleTimeString()} ${ctx.response.status} ${ctx.request.method} ${ctx.request.url} - ${ms}ms`);
  });
}

const books = [
  { id: 1, title: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction", year: 1925, ISBN: "978-3-16-148410-0", availability: "Available" },
  { id: 2, title: "To Kill a Mockingbird", author: "Harper Lee", genre: "Classic", year: 1960, ISBN: "978-0-06-112008-4", availability: "Checked Out" },
  { id: 3, title: "1984", author: "George Orwell", genre: "Dystopian", year: 1949, ISBN: "978-0-452-28423-4", availability: "Available" },
  { id: 4, title: "Pride and Prejudice", author: "Jane Austen", genre: "Romance", year: 1813, ISBN: "978-1-912254-24-4", availability: "Reserved" },
  { id: 5, title: "The Catcher in the Rye", author: "J.D. Salinger", genre: "Coming-of-age", year: 1951, ISBN: "978-0-316-76948-0", availability: "Available" },
  { id: 6, title: "Harry Potter and the Sorcerer's Stone", author: "J.K. Rowling", genre: "Fantasy", year: 1997, ISBN: "978-0-7475-3269-6", availability: "Checked Out" },
  { id: 7, title: "The Hobbit", author: "J.R.R. Tolkien", genre: "Fantasy", year: 1937, ISBN: "978-0-618-26030-0", availability: "Available" },
  { id: 8, title: "The Da Vinci Code", author: "Dan Brown", genre: "Mystery", year: 2003, ISBN: "978-0-385-50420-5", availability: "Reserved" },
  { id: 9, title: "The Alchemist", author: "Paulo Coelho", genre: "Philosophical", year: 1988, ISBN: "978-0-06-112241-5", availability: "Available" },
  { id: 10, title: "Moby-Dick", author: "Herman Melville", genre: "Adventure", year: 1851, ISBN: "978-1-85326-011-3", availability: "Checked Out" },
  { id: 11, title: "Crime and Punishment", author: "Fyodor Dostoevsky", genre: "Psychological Fiction", year: 1866, ISBN: "978-0-14-044913-6", availability: "Available" },
  { id: 12, title: "The Lord of the Rings", author: "J.R.R. Tolkien", genre: "Fantasy", year: 1954, ISBN: "978-0-345-24037-3", availability: "Checked Out" },
  { id: 13, title: "One Hundred Years of Solitude", author: "Gabriel Garcia Marquez", genre: "Magic Realism", year: 1967, ISBN: "978-0-06-112009-1", availability: "Available" },
  { id: 14, title: "The Chronicles of Narnia", author: "C.S. Lewis", genre: "Fantasy", year: 1950, ISBN: "978-0-06-623850-0", availability: "Reserved" },
  { id: 15, title: "The Shining", author: "Stephen King", genre: "Horror", year: 1977, ISBN: "978-0-385-12167-5", availability: "Available" },
  { id: 16, title: "Brave New World", author: "Aldous Huxley", genre: "Dystopian", year: 1932, ISBN: "978-0-06-085052-4", availability: "Checked Out" },
  { id: 17, title: "Wuthering Heights", author: "Emily Bronte", genre: "Gothic Fiction", year: 1847, ISBN: "978-0-19-884084-8", availability: "Available" },
  { id: 18, title: "The Odyssey", author: "Homer", genre: "Epic Poetry", year: 800, ISBN: "978-0-19-814187-1", availability: "Reserved" },
  { id: 19, title: "The Road", author: "Cormac McCarthy", genre: "Post-Apocalyptic Fiction", year: 2006, ISBN: "978-0-307-38789-9", availability: "Available" },
  { id: 20, title: "Jane Eyre", author: "Charlotte Bronte", genre: "Gothic Romance", year: 1847, ISBN: "978-1-85326-011-3", availability: "Checked Out" },
];


const router = new Router();

router.get('/all', ctx => {
  ctx.response.body = books;
  ctx.response.status = 200;
});

router.get('/genres', ctx => {
  ctx.response.body = books.map(entry => entry.genre);
  ctx.response.status = 200;
});

router.get('/books/:genre', ctx => {
  const headers = ctx.params;
  const genre = headers.genre;
  ctx.response.body = books.filter(obj => obj.genre == genre);
  ctx.response.status = 200;
});

router.get('/author/:name', ctx => {
  const headers = ctx.params;
  const name = headers.name;
  ctx.response.body = books.filter(obj => obj.author == name);
  ctx.response.status = 200;
});

router.get('/book/:id', ctx => {
  const headers = ctx.params;
  const id = headers.id;
  if (typeof id !== 'undefined') {
    const index = books.findIndex(entry => entry.id == id);
    if (index === -1) {
      const msg = "No entity with id: " + id;
      console.log(msg);
      ctx.response.body = { text: msg };
      ctx.response.status = 404;
    } else {
      let entry = books[index];
      ctx.response.body = entry;
      ctx.response.status = 200;
    }
  } else {
    ctx.response.body = { text: 'Id missing or invalid' };
    ctx.response.status = 404;
  }
});

const broadcast = (data) =>
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });

router.post('/book', ctx => {
  // console.log("ctx: " + JSON.stringify(ctx));
  const headers = ctx.request.body;
  // console.log("body: " + JSON.stringify(headers));
  const title = headers.title;
  const author = headers.author;
  const genre = headers.genre;
  const year = headers.year;
  const ISBN = headers.ISBN;
  const availability = headers.availability;
  if (typeof title !== 'undefined'
    && typeof author !== 'undefined'
    && typeof genre !== 'undefined'
    && typeof year !== 'undefined'
    && typeof ISBN !== 'undefined'
    && typeof availability !== 'undefined') {
    const index = books.findIndex(entry => entry.title == title && entry.author == author);
    if (index !== -1) {
      const msg = "The entity already exists!";
      console.log(msg);
      ctx.response.body = { text: msg };
      ctx.response.status = 404;
    } else {
      let maxId = Math.max.apply(Math, books.map(entry => entry.id)) + 1;
      let entry = {
        id: maxId,
        title,
        author,
        genre,
        year,
        ISBN,
        availability
      };
      books.push(entry);
      broadcast(entry);
      ctx.response.body = entry;
      ctx.response.status = 200;
    }
  } else {
    const msg = "Missing or invalid title: " + title + " author: " + author + " genre: " + genre
      + " year: " + year + " ISBN: " + ISBN + " availability: " + availability;
    console.log(msg);
    ctx.response.body = { text: msg };
    ctx.response.status = 404;
  }
});


router.delete('/book/:id', ctx => {
  const headers = ctx.params;
  const id = headers.id;
  if (typeof id !== 'undefined') {
    const index = books.findIndex(entry => entry.id == id);
    if (index === -1) {
      const msg = "No entity with id: " + id;
      console.log(msg);
      ctx.response.body = { text: msg };
      ctx.response.status = 404;
    } else {
      let entry = books[index];
      books.splice(index, 1);
      ctx.response.body = entry;
      ctx.response.status = 200;
    }
  } else {
    const msg = "Id missing or invalid. id: " + id;
    console.log(msg);
    ctx.response.body = { text: msg };
    ctx.response.status = 404;
  }
});

app.use(router.routes());
app.use(router.allowedMethods());

const port = 2419;

server.listen(port, () => {
  console.log(`🚀 Server listening on ${port} ... 🚀`);
});