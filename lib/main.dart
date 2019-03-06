import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MaterialApp(home: Home()));

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoController = TextEditingController();

  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;


  @override
  void initState() {
    super.initState();
    _readData().then((data){
      setState(() {
        _toDoList= json.decode(data);
      });
    });
  }

  void _addToDo(){
    if(_todoController.text.toString().isNotEmpty) {
      setState(() {
        Map<String, dynamic> newToDo = Map();
        newToDo["title"] = _todoController.text;
        _todoController.text = "";
        newToDo["ok"] = false;
        _toDoList.add(newToDo);
        _saveData();
      });
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<void> _refresh() async{

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(16.0, 1.0, 16.0, 1.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(

                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                        labelText: "Nome da tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 16.0),
                    itemCount: _toDoList.length,
                    itemBuilder: buildItem),
                onRefresh: _refresh),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index){
      return Dismissible(
        background: Container(
          color: Colors.red,
          child: Align(
            child: Icon(Icons.delete, color: Colors.white),
            alignment: Alignment(-0.9, 0.0),
          ),
        ),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(_toDoList[index]["title"]),
          onChanged: (bool value) {
            setState(() {
              _toDoList[index]["ok"] = value;
              _saveData();
            });
          },
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"]?
            Icons.check :Icons.error),
          ),
          value: _toDoList[index]["ok"],
        ),
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        onDismissed: (direction){
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida!"),
              action: SnackBarAction(label: "Desfazer", onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              }),
              duration: Duration(seconds: 2),
            );
            Scaffold.of(context).showSnackBar(snack);
          });
        },
      );
  }


}
