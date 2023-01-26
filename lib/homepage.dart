//Lib
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stacker/pixel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';

//Main Widget
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int highScore = 0;

  //Get saved high score
  Future<void> updateHs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState((){
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  //Check if score is bigger than high score
  Future<void> check(sc) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (sc > highScore) {
      setState(() async{
        highScore = sc;
        await prefs.setInt('highScore', highScore);
      });
    }
  }

  //variables
  int numberOfSquares = 160;
  List<int> piece = []; //moving piece
  var direction = 'left';
  List<int> landed = [];
  int level = 0; //height
  var temp = 0; //holds piece length temporarily
  int initializePieces = 5;
  int rowSize = 10;
  List<int> gameOver = []; //for red blink when game is over
  int score = 0;
  bool gameOn=false; //continue state
  List<Color> colors = [Colors.red, Colors.yellow, Colors.blue, Colors.white, Colors.pink, Colors.orange, Colors.brown, Colors.grey, Colors.green, Colors.purple];
  final random = math.Random();
  int speed = 100; //ms
  bool visible=false; //blink text
  String speedUpText = 'SPEED UP !';
  int normalSpeed = 100;
  int highSpeed = 50;

  //move piece
  void move(){
    //bounding
    if(piece.last%rowSize == 0) {
      direction = 'right';
    }else if(piece.first%rowSize == rowSize-1){
      direction = 'left';
    }

    //move
    setState(() {
      if (direction == 'right'){
        for (int i = 0; i < piece.length; i++) {
          piece[i] += 1;
        }
      }
      else{
        for (int i = 0; i < piece.length; i++) {
          piece[i] -= 1;
        }
      }
    });
  }

  void gameOverF() async{
    final audio= AudioPlayer();
    audio.play(AssetSource('audio/lose.wav'));
    //hide blink text
    visible=false;
    gameOn=false;
    speed = 100;
    //make red pixels' list as all
    for(int i = 0; i<numberOfSquares; i++){
      gameOver.add(i);
    }
    //after 200ms, make all pixels black again
    Future.delayed(const Duration(milliseconds: 200), () {
      setState((){gameOver=[];});
    }).then((value){
      Future.delayed(const Duration(milliseconds: 200), () {
        setState((){
          //after 200ms, make all pixels red
          for(int i = 0; i<numberOfSquares; i++){
            gameOver.add(i);
          }
        });
      }).then((value){
        Future.delayed(const Duration(milliseconds: 200), () {
          //after 200ms make all pixels black again, so its gonna blink red and reset all variables
          setState((){
            gameOver=[];
            landed=[];
            piece=[];
            level=0;
            direction = 'left';
            temp = 0;
            score = 0;
          });
        });
      });
    });
  }

  //on click
  void click(){
    //if game is continuing, click is for stack
    if(gameOn){
      stack();
    }else{
      //if game is not continuing, then start game
      startGame();
    }
  }

  //to change speed
  void startPeriod(ms){
    Timer.periodic(Duration(milliseconds: ms), (timer) {
      move();
      if(speed!=ms){
        timer.cancel();
        startPeriod(speed);
      }
    });
  }

  void startGame(){
    gameOn = true;
    //create piece
    for(int i =1; i<=initializePieces; i++){
      piece.add(numberOfSquares - i - level*rowSize);
    }
    //set speed as 100ms which is normal speed
    startPeriod(100);
  }

  void stack() async{
    setState((){
      //add stacked piece's pixels to landed list
      for (int i=0; i<piece.length; i++){
        landed.add(piece[i]);
      }
      level ++;

      //take piece to the next level and start from the beginning
      temp=piece.length;
      piece=[];
      for(int i =1; i<=temp; i++){
        piece.add(numberOfSquares - i - level*rowSize);
      }
      direction = 'left';
      // check the situation just like game over, speed up, bonus
      checkState();
    });
  }

  void checkState(){
    setState(() async{
      //get how many pieces are in collision
      var counter = 0;
      for(int i = 0; i<numberOfSquares-((level-1)*rowSize); i++){
        if(landed.contains(i)){
          counter ++;
        }
      }
      //adjust the last layer
      for (int i=0; i<landed.length; i++){
        if (!landed.contains(landed[i]+rowSize) && landed[i]+rowSize <= numberOfSquares){
          landed.remove(landed[i]);
        }
      }
      //double loop because indexes are changing and it needs a second check
      for (int i=0; i<landed.length; i++){
        if (!landed.contains(landed[i]+rowSize) && landed[i]+rowSize <= numberOfSquares){
          landed.remove(landed[i]);
        }
      }
      //recreate the piece because level changed
      piece=[];
      for(int i = 0; i<numberOfSquares-((level-1)*rowSize); i++){
        if(landed.contains(i)){
          piece.add(numberOfSquares - (piece.length+1) - level*rowSize);
        }
      }
      //if there is no pixels in collision, then game is over
      if(piece.isEmpty){

        gameOverF();
      }else{
        score++;
        //if game has sped up and stacked successfully, reset level and increase piece's length
        if(speed==highSpeed){
          final audio= AudioPlayer();
          audio.play(AssetSource('audio/reset_level.wav'));
          setState((){
            level = 0;
            landed=[];
            temp = piece.length;
            piece=[];
            if (temp==rowSize-1){
              temp+=1;
            }else if(temp!=rowSize){
              temp+=2;
            }
            for(int i =1; i<=temp; i++){
              piece.add(numberOfSquares - i - level*rowSize);
            }
          });
          //if stacked only one pixel, increase score 30 points, and show +30 text (10 points are at the end)
          if(counter == 1){
            score+=20;
            //blink +30  text
            setState((){
              speedUpText='+30';
              visible=true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              setState((){
                visible=false;
                speedUpText='SPEED UP !';
              });
            });
          }
          //if stacked only two pixels, increase score 20 points, and show +20 text
          else if(counter == 2){
            score+=10;
            setState((){
              speedUpText='+20';
              visible=true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              setState((){
                visible=false;
                speedUpText='SPEED UP !';
              });
            });
          }else{
            //blink +20 text
            setState((){
              speedUpText='+10';
              visible=true;
            });
            Future.delayed(const Duration(milliseconds: 500), () {
              setState((){
                visible=false;
                speedUpText='SPEED UP !';
              });
            });
          }
          speed=normalSpeed;
          score+=10;
        }
        //if score is a multiple of 10, than speed up
        if(score%10==0 && score!=0){
          speed=highSpeed;
          visible=true;
          speedUpText = 'SPEED UP !';
        }
      }
      check(score);
      updateHs();
    });
  }

  @override
  Widget build(BuildContext context) {
    updateHs();
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: click,
        child: Column(
          children: [
            Expanded(
                flex: 6,
                child: GridView.builder(
                    itemCount: numberOfSquares,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: rowSize),
                    itemBuilder: (BuildContext context, int index) {
                      //for game over red blink
                      if(gameOver.contains(index)){
                        return const MyPixel(color:Colors.red);
                      }
                      //if speeding up, then change piece's colors
                      else if(piece.contains(index)){
                        if(speed==highSpeed){
                          return MyPixel(color: colors[random.nextInt(colors.length)]);
                        }
                        else{
                          return const MyPixel(color: Colors.white);
                        }
                      }
                      //if speeding up, then change piece's colors
                      else if(landed.contains(index)){
                        if(speed==highSpeed){
                          return MyPixel(color: colors[random.nextInt(colors.length)]);
                        }
                        else{
                          return const MyPixel(color: Colors.white);
                        }
                      }
                      else{
                        return const MyPixel(color: Colors.black);
                      }
                    })),
            //blinking text
            Visibility(
              visible: visible,
              child: Text(
                speedUpText,
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontFamily: 'Pixelated'
                ),
              ),
            ),
            //score
            Expanded(child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                'S: $score',
                style: const TextStyle(
                  fontSize: 30,
                  color: Colors.white,
                  fontFamily: 'Pixelated'
                ),

              ),
                Text(
                  'HS: $highScore',
                  style: const TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                    fontFamily: 'Pixelated'
                  ),
                ),
              ]
            ),
            ),
          ],
        ),
      ),
    );
  }
}
