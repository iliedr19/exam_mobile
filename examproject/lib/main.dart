import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Registration',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BookListScreen(),
    );
  }
}

class BookListScreen extends StatefulWidget {
  @override
  _BookListScreenState createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<dynamic> books = [];

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:2419/all'));

      if (response.statusCode == 200) {
        setState(() {
          books = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error loading books: $e');
      throw Exception('Failed to load books');
    }
  }

  Future<void> addBook(String title, String author, String genre, int year, String isbn, String availability) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:2419/book'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'author': author,
        'genre': genre,
        'year': year,
        'ISBN': isbn,
        'availability': availability,
      }),
    );

    if (response.statusCode == 200) {
      // Refresh the list of books after adding a new book
      fetchBooks();
    } else {
      throw Exception('Failed to add book');
    }
  }

  Future<void> deleteBook(int id) async {
    final response = await http.delete(Uri.parse('http://10.0.2.2:2419/book/$id'));

    if (response.statusCode == 200) {
      // Refresh the list of books after deleting the book
      fetchBooks();
    } else {
      throw Exception('Failed to delete book');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Registration'),
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(books[index]['title']),
            subtitle: Text(books[index]['author']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsScreen(
                    book: books[index],
                    onDelete: deleteBook,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBookDialog(context);
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      persistentFooterButtons: [
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OwnerSectionScreen()),
            );
          },
          child: Text('Author Section'),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ReportSectionScreen()),
            );
          },
          child: Text('Report Section'),
        ),
      ],
    );
  }

  Future<void> _showAddBookDialog(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController authorController = TextEditingController();
    TextEditingController genreController = TextEditingController();
    TextEditingController yearController = TextEditingController();
    TextEditingController isbnController = TextEditingController();
    TextEditingController availabilityController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Book'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: authorController,
                  decoration: InputDecoration(labelText: 'Author'),
                ),
                TextField(
                  controller: genreController,
                  decoration: InputDecoration(labelText: 'Genre'),
                ),
                TextField(
                  controller: yearController,
                  decoration: InputDecoration(labelText: 'Year'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: isbnController,
                  decoration: InputDecoration(labelText: 'ISBN'),
                ),
                TextField(
                  controller: availabilityController,
                  decoration: InputDecoration(labelText: 'Availability'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Add'),
              onPressed: () {
                addBook(
                  titleController.text,
                  authorController.text,
                  genreController.text,
                  int.tryParse(yearController.text) ?? 0,
                  isbnController.text,
                  availabilityController.text,
                );
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class BookDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> book;
  final Function(int) onDelete;

  BookDetailsScreen({required this.book, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book['title']),
        actions: [
          IconButton(
            onPressed: () {
              _showConfirmationDialog(context);
            },
            icon: Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Author: ${book['author']}'),
            Text('Genre: ${book['genre']}'),
            Text('Year: ${book['year']}'),
            Text('ISBN: ${book['ISBN']}'),
            Text('Availability: ${book['availability']}'),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this book?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the confirmation dialog
                onDelete(book['id']); // Delete the book
                Navigator.pop(context); // Return to the main screen
              },
            ),
          ],
        );
      },
    );
  }
}

class OwnerSectionScreen extends StatefulWidget {
  @override
  _OwnerSectionScreenState createState() => _OwnerSectionScreenState();
}

class _OwnerSectionScreenState extends State<OwnerSectionScreen> {
  late String authorName = '';

  @override
  void initState() {
    super.initState();
    _loadAuthorName();
  }

  Future<void> _loadAuthorName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      authorName = prefs.getString('authorName') ?? '';
    });
  }

  Future<void> _saveAuthorName(String name) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('authorName', name);
    setState(() {
      authorName = name;
    });
  }

  Future<void> _viewAuthorBooks(String authorName) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:2419/author/$authorName'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> authorBooks = json.decode(response.body);

        // Display the author's books
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Books by $authorName'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: authorBooks.map<Widget>((book) {
                    return ListTile(
                      title: Text(book['title']),
                      subtitle: Text('Author: ${book['author']}, Genre: ${book['genre']}'),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to fetch author\'s books');
      }
    } catch (e) {
      print('Error viewing author\'s books: $e');
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner Section'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record Author\'s Name:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              decoration: InputDecoration(labelText: 'Author Name'),
              onChanged: (value) {
                authorName = value;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _saveAuthorName(authorName);
              },
              child: Text('Save Author\'s Name'),
            ),
            SizedBox(height: 40),
            Text(
              'View Author\'s Books:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _viewAuthorBooks(authorName);
              },
              child: Text('View Books by Author'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportSectionScreen extends StatefulWidget {
  @override
  _ReportSectionScreenState createState() => _ReportSectionScreenState();
}

class _ReportSectionScreenState extends State<ReportSectionScreen> {
  List<String> genres = [];

  @override
  void initState() {
    super.initState();
    fetchGenres();
  }

  Future<void> fetchGenres() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:2419/genres'));

      if (response.statusCode == 200) {
        setState(() {
          genres = List<String>.from(json.decode(response.body));
        });
      } else {
        throw Exception('Failed to load genres');
      }
    } catch (e) {
      print('Error loading genres: $e');
      throw Exception('Failed to load genres');
    }
  }

  Future<void> viewBooksByGenre(String genre) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:2419/books/$genre'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> genreBooks = json.decode(response.body);

        // Display the books by genre
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Books in $genre Genre'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: genreBooks.map<Widget>((book) {
                    return ListTile(
                      title: Text(book['title']),
                      subtitle: Text('Author: ${book['author']}, Genre: ${book['genre']}'),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to fetch books by genre');
      }
    } catch (e) {
      print('Error viewing books by genre: $e');
      // Handle error
    }
  }

  Future<void> viewTop10Books() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:2419/all'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> allBooks = json.decode(response.body);

        // Sort books by publication year in descending order
        allBooks.sort((a, b) => b['year'].compareTo(a['year']));

        // Take top 10 books
        List<dynamic> top10Books = allBooks.take(10).toList();

        // Display the top 10 books
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Top 10 Books'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: top10Books.map<Widget>((book) {
                    return ListTile(
                      title: Text(book['title']),
                      subtitle: Text('Author: ${book['author']}, Availability: ${book['availability']}'),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to fetch top 10 books');
      }
    } catch (e) {
      print('Error viewing top 10 books: $e');
      // Handle error
    }
  }

  Future<void> viewTop5Authors() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:2419/all'));

      if (response.statusCode == 200) {
        // Parse the response body
        List<dynamic> allBooks = json.decode(response.body);

        // Count the occurrences of each author
        Map<String, int> authorCounts = {};
        allBooks.forEach((book) {
          String author = book['author'];
          authorCounts[author] = (authorCounts[author] ?? 0) + 1;
        });

        // Sort authors by the number of books in descending order
        List<MapEntry<String, int>> sortedAuthors = authorCounts.entries.toList();
        sortedAuthors.sort((a, b) => b.value.compareTo(a.value));

        // Take top 5 authors
        List<MapEntry<String, int>> top5Authors = sortedAuthors.take(5).toList();

        // Display the top 5 authors
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Top 5 Authors'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: top5Authors.map<Widget>((entry) {
                    return ListTile(
                      title: Text(entry.key),
                      subtitle: Text('Number of Books: ${entry.value}'),
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        throw Exception('Failed to fetch top 5 authors');
      }
    } catch (e) {
      print('Error viewing top 5 authors: $e');
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Section'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'View Genres:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Genres'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: genres.map<Widget>((genre) {
                            return ListTile(
                              title: Text(genre),
                            );
                          }).toList(),
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Close'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('View Genres'),
            ),
            SizedBox(height: 40),
            Text(
              'View Books by Genre:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            DropdownButton<String>(
              hint: Text('Select Genre'),
              value: null,
              items: genres.map((String genre) {
                return DropdownMenuItem<String>(
                  value: genre,
                  child: Text(genre),
                );
              }).toList(),
              onChanged: (String? selectedGenre) {
                if (selectedGenre != null) {
                  viewBooksByGenre(selectedGenre);
                }
              },
            ),
            SizedBox(height: 40),
            Text(
              'Top 10 Books:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                viewTop10Books();
              },
              child: Text('View Top 10 Books'),
            ),
            SizedBox(height: 40),
            Text(
              'Top 5 Authors:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                viewTop5Authors();
              },
              child: Text('View Top 5 Authors'),
            ),
          ],
        ),
      ),
    );
  }
}
