import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Path Visualizer',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: DijkstraGrid(),
    );
  }
}

class Node {
  final int row, col;
  bool isStart = false;
  bool isEnd = false;
  bool isWall = false;
  bool isVisited = false;
  bool isPath = false;
  Node? previousNode;
  double distance = double.infinity;
  bool hasSelectedDestination = false;

  Node(this.row, this.col);

  List<Node> getNeighbors(List<List<Node>> grid) {
    List<Node> neighbors = [];
    if (row > 0) neighbors.add(grid[row - 1][col]);
    if (row < grid.length - 1) neighbors.add(grid[row + 1][col]);
    if (col > 0) neighbors.add(grid[row][col - 1]);
    if (col < grid[0].length - 1) neighbors.add(grid[row][col + 1]);
    return neighbors
        .where((neighbor) => !neighbor.isWall && !neighbor.isVisited)
        .toList();
  }
}

class DijkstraGrid extends StatefulWidget {
  @override
  _DijkstraGridState createState() => _DijkstraGridState();
}

class _DijkstraGridState extends State<DijkstraGrid> {
  static const int rowCount = 20;
  static const int colCount = 10;
  late List<List<Node>> grid;

  Node? startNode;
  Node? endNode;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  Widget _nodeIcon(Node node) {
    if (node.isStart) {
      return Tooltip(
          message: 'Start',
          child: Icon(Icons.flag, color: Colors.green, size: 30));
    } else if (node.isEnd) {
      return Tooltip(
          message: 'End',
          child: Icon(Icons.location_on, color: Colors.amber, size: 30));
    } else if (node.isVisited) {
      return Tooltip(
          message: 'Bus',
          child: Icon(Icons.block, color: Colors.red, size: 30));
    } else if (node.isPath) {
      return Tooltip(
          message: 'Path',
          child: Icon(Icons.directions_bus,
              color: Colors.lightBlueAccent, size: 30));
    } else if (node.isWall) {
      return Tooltip(
          message: 'Wall',
          child: Icon(Icons.block, color: Colors.black, size: 30));
    } else if (node.hasSelectedDestination) {
      return Tooltip(
          message: 'Cell',
          child:
              Icon(Icons.crop_square, color: Colors.blueGrey[100], size: 30));
    } else {
      return Tooltip(
          message: 'Cell',
          child: Icon(Icons.crop_square, color: Colors.grey[300], size: 30));
    }
  }

  _initializeGrid() {
    grid = List.generate(
        rowCount, (row) => List.generate(colCount, (col) => Node(row, col)));
  }

  _onCellTap(Node node) {
    if (startNode == null) {
      setState(() {
        startNode = node;
        node.isStart = true;
      });
    } else if (endNode == null && node != startNode) {
      setState(() {
        endNode = node;
        node.isEnd = true;
        for (var row in grid) {
          for (var n in row) {
            n.hasSelectedDestination = true;
          }
        }
      });
    } else {
      setState(() {
        node.isWall = !node.isWall;
      });
    }
  }

  _computeDijkstra() {
    if (startNode == null || endNode == null) return;

    List<Node> unvisitedNodes = [];
    grid.forEach((row) => row.forEach((node) => unvisitedNodes.add(node)));

    startNode!.distance = 0;

    while (unvisitedNodes.isNotEmpty) {
      unvisitedNodes.sort((a, b) => a.distance.compareTo(b.distance));

      Node currentNode = unvisitedNodes.removeAt(0);
      if (currentNode.isWall) continue;
      if (currentNode.distance == double.infinity) break;

      currentNode.isVisited = true;

      if (currentNode == endNode) {
        _reconstructPath(endNode);
        return;
      }

      for (var neighbor in currentNode.getNeighbors(grid)) {
        double distance = currentNode.distance + 1;
        if (distance < neighbor.distance) {
          neighbor.distance = distance;
          neighbor.previousNode = currentNode;
        }
      }
    }
  }

  _reconstructPath(Node? endNode) async {
    Node? currentNode = endNode;
    while (currentNode != null) {
      await Future.delayed(Duration(milliseconds: 500), () {
        setState(() {
          currentNode!.isVisited = false;
          currentNode!.isPath = true;
        });
      });
      currentNode = currentNode.previousNode;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        title: Text('Path Visualizer'),
        centerTitle: true,
        elevation: 8.0,
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: colCount),
                itemCount: rowCount * colCount,
                itemBuilder: (context, index) {
                  int row = index ~/ colCount;
                  int col = index % colCount;
                  Node node = grid[row][col];
                  return GestureDetector(
                    onTap: () => _onCellTap(node),
                    child: GridTile(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.lightBlue[50],
                          border: Border.all(
                              color: Colors.lightBlueAccent.shade700,
                              width: 0.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueGrey[200]!,
                              offset: Offset(0.0, 1.0),
                              blurRadius: 3.0,
                            ),
                          ],
                        ),
                        child: Center(child: _nodeIcon(node)),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: _computeDijkstra,
                  icon: Icon(Icons.play_arrow),
                  label: Text('Start Algorithm'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    shadowColor: Colors.blueGrey[200],
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initializeGrid();
                      startNode = null;
                      endNode = null;
                    });
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Reset Grid'),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    onPrimary: Colors.white,
                    shadowColor: Colors.blueGrey[200],
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32.0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
