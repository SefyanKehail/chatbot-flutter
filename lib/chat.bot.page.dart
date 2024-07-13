import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;

class ChatBotPage extends StatefulWidget {
  ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  TextEditingController promptController = TextEditingController();
  ScrollController scrollController = ScrollController();

  List messages = [
    {"text": "Hello! How can I help you?", "type": "assistant"},
  ];

  String OPENAI_API_KEY = "";
  bool isTyping = false;


  @override
  Widget build(BuildContext context) {

    Map<String, String>? args = ModalRoute.of(context)?.settings.arguments as Map<String, String>?;
    String? conversationTitle = args?["title"]!;


    return Scaffold(
      appBar: AppBar(
        title: Text(
          conversationTitle ?? "New Conversation",
          style: TextStyle(
            color: Theme.of(context).indicatorColor,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  bool isUser = messages[index]["type"] == "user";
                  return Align(
                    alignment:
                    isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isUser
                            ? Theme.of(context).focusColor
                            : Theme.of(context).primaryColorLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        messages[index]['text'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  SpinKitThreeBounce(
                    color: Theme.of(context).primaryColor,
                    size: 20.0,
                  ),
                  SizedBox(width: 10),
                  Text("Assistant is typing...",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: promptController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          width: 1,
                          color: Theme.of(context).primaryColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: () {
                    String prompt = promptController.text;
                    setState(() {
                      isTyping = true;
                      messages.add({"text": prompt, "type": "user"});
                    });
                    promptController.clear();

                    Uri uri =
                    Uri.https("mockgpt.wiremockapi.cloud", "/v1/chat/completions");
                    Map<String, String> headers = {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer $OPENAI_API_KEY",
                    };

                    var body = {
                      "model": "gpt-3.5-turbo",
                      "messages": [
                        {
                          "role": "system",
                          "content":
                          "You are a poetic assistant, skilled in explaining complex programming concepts with creative flair."
                        },
                        {"role": "user", "content": prompt},
                      ]
                    };
                    http
                        .post(uri, headers: headers, body: json.encode(body))
                        .then(
                          (response) {
                        try {
                          var responseBody = json.decode(response.body);
                          var answer =
                          responseBody["choices"][0]["message"]["content"];

                          setState(() {
                            isTyping = false;
                            messages.add({"text": answer, "type": "assistant"});
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            scrollController.animateTo(
                              scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });
                        } catch (err) {
                          setState(() {
                            isTyping = false;
                            messages.add({
                              "text": "Something went wrong with the API call",
                              "type": "assistant"
                            });
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            scrollController.animateTo(
                              scrollController.position.maxScrollExtent,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          });

                          print("Error: $err");
                        }
                      },
                      onError: (err) {
                        setState(() {
                          isTyping = false;
                          messages.add({
                            "text": "Something went wrong with the API call",
                            "type": "assistant"
                          });
                        });

                        print("Error: $err");
                      },
                    );
                  },
                  child: Icon(Icons.send),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
