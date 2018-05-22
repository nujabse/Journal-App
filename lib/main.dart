import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;


void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Mood Journal',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(storage: new CounterStorage(),),
    );
  }
}

class CounterStorage {

  // Get the directory
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
  // get the file
  Future<File> get _localFile async {
    final path = await _localPath;
    return new File('$path/counter.txt');
  }
  Future<int> readCounter() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      return int.parse(contents);
    } catch (e) {
      return 0;
    }
  }
  Future<File> writeCounter(int counter) async {
    final file = await _localFile;
    // write the file
    return file.writeAsStringSync('$counter');
  }
}

class MoodStorage {
  void createFile(Map<String, String> content, Directory dir, String filename, bool fileExists) {
    print("Mood file creating now!");
    File file = new File(dir.path + "/" + filename);
    file.createSync();
    fileExists = true;
    file.writeAsStringSync(json.encode(content));
  }

  void writeToFile(String key, String value, File jsonFile, bool fileExists, Directory dir, String filename) {
    print("Writing to file now!");
    Map<String, String> content = {key: value};
    if (fileExists) {
      print("File Exists!");
      Map<String, dynamic> jsonFileContent = json.decode(jsonFile.readAsStringSync());
      jsonFileContent.addAll(content);
      jsonFile.writeAsStringSync(json.encode(jsonFileContent));
    } else {
      print("File not exixt!");
      createFile(content, dir, filename, fileExists);
    }
  }
}

class MyHomePage extends StatefulWidget {
  final CounterStorage storage;

  MyHomePage({Key key,  this.storage}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    widget.storage.readCounter().then((int value) {
      setState(() {
        _counter = value;
      });
    });
  }

  void takeNote() {
    setState(() {
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new NotePage(storage: new CounterStorage(),)));
    });
  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('心情日志'),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Text(
              '您已经连续记录：',
            ),
            new Text(
              '$_counter 条日志',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: takeNote,

        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class NotePage extends StatefulWidget {
  final CounterStorage storage;
  NotePage({Key key,  this.storage}) : super(key: key);
  @override
  _NotePageState createState() => new _NotePageState();
}

class _NotePageState extends State<NotePage> {
  int _counter = 0;
  int _selected = 0;
  int index = 0;
  File jsonFile;
  Directory dir;
  String fileName = "mood.json";
  bool fileExists = false;
  Map<String, dynamic> fileContent;

  MoodStorage mood;
  // todo: Add date and time to file name.

  @override
  void initState() {
    super.initState();
    widget.storage.readCounter().then((int value) {
      setState(() {
        _counter = value;
      });
    });
    getApplicationDocumentsDirectory().then((Directory directory) {
      dir = directory;
      jsonFile = new File(dir.path + "/" + fileName);
      fileExists = jsonFile.existsSync();
      if (fileExists) this.setState(() => fileContent = json.decode(jsonFile.readAsStringSync()));
    });
  }

  void onChanged(int value) {
    setState(() {
      _selected = value;
    });

    print('current value is $value');
  }


  Future<File> _changPage(index) async {
    setState(() {
      this.index = index;
      if (index == 0) {
        _counter++;
        String moodValue = _selected.toString();
        print('开始新建笔记');
        String time = new DateFormat.yMd().add_jm().format(new DateTime.now()).toString();
        mood = new MoodStorage();
        print(fileExists);
        mood.writeToFile(time, moodValue, jsonFile, fileExists, dir, fileName);
//        print(mood.toString());
      }
      else {
        print('Return back to home');
      }
      // Done: check whether the user really has inputted her mood.
      Navigator.push(context, new MaterialPageRoute(builder: (context) => new MyHomePage(storage: new CounterStorage())));
    });
    // todo: add seperate storage.
    print('$_counter');
    return widget.storage.writeCounter(_counter);
  }

  List<Widget> makeRadioList() {
    List<Widget> list = new List<Widget>();
    for (int i =-2; i < 3; i++) {
      list.add(new RadioListTile(
        value: i,
        title: new Text('心情  $i'),
        activeColor: Colors.deepOrange,
        // Todo: add color changing feature.
        groupValue: _selected,
        onChanged: (int value){onChanged(value);},
        subtitle: new Text('心情值'),
        secondary: new Icon(Icons.favorite),
      ));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('选择心情值'),
      ),
      body: new Container(
        padding: new EdgeInsets.all(35.0),
        child: new Center(
          child: new Column(
            children:
            makeRadioList(),
          ),
        ),
      ), 
      bottomNavigationBar: new BottomNavigationBar(
          currentIndex: index,
          onTap: (int index) {_changPage(index);},
          items: <BottomNavigationBarItem>[
            new BottomNavigationBarItem(
                icon: new Icon(Icons.done),
                title: new Text('确定')),
            new BottomNavigationBarItem(
                icon: new Icon(Icons.clear),
                title: new Text('放弃')),
          ],
      )
    );
  }
}

